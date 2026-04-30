package com.example.widget_class

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.util.Calendar

object WidgetBackgroundSync {
    private const val prefsName = "HomeWidgetPreferences"
    private const val supabaseUrl = "https://ssvuyaolsawcyordeyzw.supabase.co"
    private const val supabaseKey = "sb_publishable_AI0L1R5fzKVxqWQ8LFIq4w_q2tGn7E_"
    private const val visibleAfterStartMinutes = 30

    @Volatile
    private var running = false

    fun refreshAsync(context: Context) {
        if (running) return
        running = true
        val appContext = context.applicationContext
        Thread {
            try {
                sync(appContext)
            } catch (_: Exception) {
                // Mantem o ultimo dado salvo se o aparelho estiver sem rede.
            } finally {
                running = false
            }
        }.start()
    }

    fun sync(context: Context) {
        val prefs = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
        val turmaId = prefs.getString("selected_turma_id", "eletronica_3a") ?: "eletronica_3a"
        val aulas = fetchAulas(turmaId)
        val atividades = fetchAtividades(turmaId)

        val editor = prefs.edit()
        writeNextClass(editor, findNextClass(aulas))
        writeActivities(editor, atividades)
        editor.apply()

        ClassScheduleWidgetProvider.updateAll(context, prefs)
        ActivitiesWidgetProvider.updateAll(context, prefs)
    }

    private fun fetchAulas(turmaId: String): List<ClassRow> {
        val encodedTurma = URLEncoder.encode(turmaId, "UTF-8")
        val rows = fetchArray(
            "aulas",
            "select=disciplina,professor,sala,dia_semana,horario_inicio,horario_fim,icone,cor_hex" +
                "&turma_id=eq.$encodedTurma&order=dia_semana.asc,horario_inicio.asc",
        )
        return List(rows.length()) { index ->
            val row = rows.getJSONObject(index)
            ClassRow(
                disciplina = row.optString("disciplina", "Sem aula restante"),
                professor = row.optString("professor", "Nenhum professor"),
                sala = row.optString("sala", "Sem sala"),
                diaSemana = row.optInt("dia_semana", 1),
                horarioInicio = row.optString("horario_inicio", "00:00:00"),
                horarioFim = row.optString("horario_fim", ""),
                icone = row.optString("icone", "📘"),
                corHex = row.optString("cor_hex", "#1B9AAA"),
            )
        }
    }

    private fun fetchAtividades(turmaId: String): List<ActivityRow> {
        val encodedTurma = URLEncoder.encode(turmaId, "UTF-8")
        val rows = fetchArray(
            "atividades",
            "select=materia,titulo,tipo,data_entrega,cor_hex" +
                "&turma_id=eq.$encodedTurma&order=data_entrega.asc",
        )
        return List(rows.length()) { index ->
            val row = rows.getJSONObject(index)
            ActivityRow(
                materia = row.optString("materia", "Agenda"),
                titulo = row.optString("titulo", "Sem atividade"),
                tipo = row.optString("tipo", "trabalho"),
                dataEntrega = row.optString("data_entrega", todayKey()),
                corHex = row.optString("cor_hex", "#1B9AAA"),
            )
        }
    }

    private fun fetchArray(table: String, query: String): JSONArray {
        val connection = URL("$supabaseUrl/rest/v1/$table?$query")
            .openConnection() as HttpURLConnection
        connection.requestMethod = "GET"
        connection.setRequestProperty("apikey", supabaseKey)
        connection.setRequestProperty("Authorization", "Bearer $supabaseKey")
        connection.setRequestProperty("Accept", "application/json")
        connection.connectTimeout = 10000
        connection.readTimeout = 10000

        val responseCode = connection.responseCode
        val stream = if (responseCode in 200..299) {
            connection.inputStream
        } else {
            connection.errorStream
        }
        val body = stream.bufferedReader().use { it.readText() }
        if (responseCode !in 200..299) {
            throw IOException("Supabase HTTP $responseCode: $body")
        }
        return JSONArray(body)
    }

    private fun findNextClass(aulas: List<ClassRow>): ClassRow? {
        val calendar = Calendar.getInstance()
        val weekday = calendarWeekdayToAppWeekday(calendar.get(Calendar.DAY_OF_WEEK))
        val nowMinutes = calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)
        val today = aulas
            .filter { it.diaSemana == weekday }
            .sortedBy { it.startMinutes }

        val active = today
            .filter {
                it.startMinutes <= nowMinutes &&
                    nowMinutes <= it.startMinutes + visibleAfterStartMinutes
            }
            .maxByOrNull { it.startMinutes }

        return active ?: today.firstOrNull { it.startMinutes >= nowMinutes }
    }

    private fun writeNextClass(editor: SharedPreferences.Editor, aula: ClassRow?) {
        editor
            .putString("current_disciplina", aula?.disciplina ?: "Sem aula restante")
            .putString("current_professor", aula?.professor ?: "Nenhum professor")
            .putString("current_sala", aula?.sala ?: "Sem sala")
            .putString("current_horario", aula?.displayTime ?: "--:--")
            .putString("current_icone", aula?.icone ?: "📘")
            .putString("current_cor_hex", aula?.corHex ?: "#1B9AAA")
    }

    private fun writeActivities(
        editor: SharedPreferences.Editor,
        atividades: List<ActivityRow>,
    ) {
        val today = todayKey()
        val nextWork = atividades
            .filter { it.tipo == "trabalho" && it.dataEntrega >= today }
            .minByOrNull { it.dataEntrega }
        val nextEvaluation = atividades
            .filter { it.tipo == "avaliacao" && it.dataEntrega >= today }
            .minByOrNull { it.dataEntrega }

        editor
            .putString("work_title", nextWork?.titulo ?: "Sem trabalhos")
            .putString("work_subject", nextWork?.materia ?: "Agenda livre")
            .putString("work_date", nextWork?.displayDate ?: "--")
            .putString("work_color_hex", nextWork?.corHex ?: "#1B9AAA")
            .putString("eval_title", nextEvaluation?.titulo ?: "Sem avaliacoes")
            .putString("eval_subject", nextEvaluation?.materia ?: "Agenda livre")
            .putString("eval_date", nextEvaluation?.displayDate ?: "--")
            .putString("eval_color_hex", nextEvaluation?.corHex ?: "#5B7CFA")
    }

    private fun calendarWeekdayToAppWeekday(day: Int): Int {
        return when (day) {
            Calendar.MONDAY -> 1
            Calendar.TUESDAY -> 2
            Calendar.WEDNESDAY -> 3
            Calendar.THURSDAY -> 4
            Calendar.FRIDAY -> 5
            Calendar.SATURDAY -> 6
            else -> 7
        }
    }

    private fun todayKey(): String {
        val calendar = Calendar.getInstance()
        return "%04d-%02d-%02d".format(
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
            calendar.get(Calendar.DAY_OF_MONTH),
        )
    }

    private data class ClassRow(
        val disciplina: String,
        val professor: String,
        val sala: String,
        val diaSemana: Int,
        val horarioInicio: String,
        val horarioFim: String,
        val icone: String,
        val corHex: String,
    ) {
        val startMinutes: Int = minutesFromTime(horarioInicio)
        val displayTime: String =
            if (horarioFim.isBlank() || horarioFim == "null") {
                horarioInicio.take(5)
            } else {
                "${horarioInicio.take(5)} - ${horarioFim.take(5)}"
            }
    }

    private data class ActivityRow(
        val materia: String,
        val titulo: String,
        val tipo: String,
        val dataEntrega: String,
        val corHex: String,
    ) {
        val displayDate: String = displayDate(dataEntrega)
    }

    private fun minutesFromTime(value: String): Int {
        val parts = value.split(":")
        val hours = parts.getOrNull(0)?.toIntOrNull() ?: 0
        val minutes = parts.getOrNull(1)?.toIntOrNull() ?: 0
        return hours * 60 + minutes
    }

    private fun displayDate(value: String): String {
        val parts = value.split("-")
        val day = parts.getOrNull(2)?.toIntOrNull() ?: return "--"
        val monthIndex = (parts.getOrNull(1)?.toIntOrNull() ?: return "--") - 1
        val month = monthNames.getOrNull(monthIndex) ?: return "--"
        return "$day de $month"
    }

    private val monthNames = listOf(
        "janeiro",
        "fevereiro",
        "marco",
        "abril",
        "maio",
        "junho",
        "julho",
        "agosto",
        "setembro",
        "outubro",
        "novembro",
        "dezembro",
    )
}
