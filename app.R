# =============================================================================
#  DASHBOARD SHINY · Model Selection dengan AIC/AICc dan Cross-Validation (CCPP)
#
#  Dashboard ini HANYA MEMBACA hasil analisis yang sudah disimpan oleh R.Rmd
#  (berkas `hasil_analisis_dashboard.rds`). Tidak ada model yang dihitung ulang.
#
#  Cara pakai:
#    1. Knit R.Rmd (versi yang sudah dimodifikasi) -> menghasilkan
#       hasil_analisis_dashboard.rds
#    2. Letakkan berkas .rds itu di folder yang sama dengan app.R
#    3. shiny::runApp()
# =============================================================================
setwd("D:\\FASTTRACK S2\\REGRESI\\PROJECT\\dashboard_rshiny")
suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(plotly)
  library(htmltools)
})

APP_TITLE <- "Model Selection Menggunakan AIC dan CV"
RESULTS_FILE_CANDIDATES <- c("hasil_analisis_dashboard.rds",
                             file.path("..", "hasil_analisis_dashboard.rds"))

# -----------------------------------------------------------------------------
# Memuat hasil analisis (sekali, saat aplikasi dijalankan)
# -----------------------------------------------------------------------------
find_results_file <- function() {
  for (p in RESULTS_FILE_CANDIDATES) if (file.exists(p)) return(normalizePath(p))
  NULL
}
RESULTS_PATH <- find_results_file()
LOAD_ERROR <- NULL
PAYLOAD <- NULL
if (is.null(RESULTS_PATH)) {
  LOAD_ERROR <- paste0("File hasil analisis `hasil_analisis_dashboard.rds` tidak ditemukan. ",
                       "Knit R.Rmd sampai selesai, lalu letakkan file hasilnya di folder yang sama dengan app.R.")
} else {
  PAYLOAD <- tryCatch(readRDS(RESULTS_PATH), error = function(e) e)
  if (inherits(PAYLOAD, "error")) {
    LOAD_ERROR <- paste("File hasil analisis tidak dapat dibaca:", conditionMessage(PAYLOAD))
    PAYLOAD <- NULL
  }
}

# -----------------------------------------------------------------------------
# Gaya (CSS) -- mengikuti tampilan App.py
# -----------------------------------------------------------------------------
APP_CSS <- "
:root{--bg:#f5f7fb;--panel:#fff;--text:#152033;--muted:#5d6b82;--accent:#5967f2;--accent2:#11a7a0;--border:rgba(21,32,51,.10);}
html,body{background:radial-gradient(circle at 8% 0%,rgba(89,103,242,.10),transparent 28%),radial-gradient(circle at 90% 6%,rgba(17,167,160,.08),transparent 24%),var(--bg) !important;color:var(--text);}
body{font-family:Inter,'Segoe UI',system-ui,-apple-system,BlinkMacSystemFont,sans-serif;}
.bslib-page-sidebar>.main,.main{background:transparent !important;padding:1.25rem 1.6rem 5rem !important;}
.bslib-sidebar-layout>.sidebar{background:linear-gradient(180deg,#fff,#f4f7fb) !important;border-right:1px solid var(--border) !important;}
.sidebar-content{padding:1.1rem 1rem !important;}
.brand{font-weight:780;font-size:1.05rem;letter-spacing:.02em;color:#152033;}
.small-muted{color:#65738a;font-size:.86rem;}
.nav-radio .shiny-options-group{display:flex;flex-direction:column;gap:.35rem;margin-top:.4rem;}
.nav-radio .radio,.nav-radio .form-check{margin:0;padding:0;}
.nav-radio label{display:block;width:100%;padding:.55rem .75rem;border-radius:12px;border:1px solid transparent;cursor:pointer;font-size:.9rem;color:#334155;transition:all .15s;}
.nav-radio label:hover{background:rgba(89,103,242,.07);}
.nav-radio input[type=radio]{display:none;}
.nav-radio input[type=radio]:checked+span{font-weight:720;color:#3f4bc0;}
.nav-radio .radio:has(input:checked) label,.nav-radio .form-check:has(input:checked) label{background:rgba(89,103,242,.10);border-color:rgba(89,103,242,.22);}
.nav-title{font-size:.72rem;letter-spacing:.12em;color:#6d7890;font-weight:700;margin-top:.9rem;}
.hero{padding:1.35rem 1.55rem;border:1px solid rgba(89,103,242,.13);border-radius:22px;background:linear-gradient(135deg,rgba(89,103,242,.10),rgba(17,167,160,.06) 65%,rgba(255,255,255,.78));box-shadow:0 18px 50px rgba(50,67,100,.08);margin-bottom:1rem;}
.hero-title{font-size:2.1rem;font-weight:780;letter-spacing:-.035em;margin:0;color:#152033;}
.hero-sub{color:#56647b;margin-top:.35rem;font-size:1rem;}
.section-title{font-size:1.18rem;font-weight:720;margin:1.1rem 0 .55rem;color:#152033;}
.section-label{font-size:12px;font-weight:780;color:#44516a;margin:12px 0 7px;}
.metric-card{background:rgba(255,255,255,.93);border:1px solid var(--border);border-radius:18px;padding:1rem 1.05rem;min-height:110px;box-shadow:0 10px 28px rgba(50,67,100,.07);height:100%;}
.metric-label{color:#627089;font-size:.78rem;text-transform:uppercase;letter-spacing:.08em;}
.metric-value{color:#152033;font-size:1.55rem;font-weight:760;margin-top:.3rem;line-height:1.2;}
.metric-note{color:#718096;font-size:.76rem;margin-top:.2rem;}
.card-row{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:.9rem;margin:.2rem 0 1rem;}
.badge-x{display:inline-block;padding:.26rem .55rem;border-radius:999px;font-size:.76rem;font-weight:650;background:rgba(89,103,242,.10);border:1px solid rgba(89,103,242,.20);color:#4b58d5;}
.badge-green{background:rgba(17,167,160,.10);border-color:rgba(17,167,160,.20);color:#0c817b;}
.note{border-left:3px solid var(--accent);padding:.75rem .95rem;background:rgba(89,103,242,.055);border-radius:0 12px 12px 0;color:#334155;font-size:.9rem;margin:.6rem 0 1rem;}
.note.warn{border-left-color:#e48620;background:rgba(228,134,32,.07);}
.caption-line{color:#65738a;font-size:.84rem;margin:.35rem 0 .8rem;}
.controls{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px;padding:10px 0 13px;}
.control{background:#f3f6fc;border:1px solid rgba(21,32,51,.08);border-radius:12px;padding:9px 12px 4px;}
.control .label{display:flex;justify-content:space-between;gap:10px;font-size:11px;font-weight:750;color:#516078;margin-bottom:2px;}
.control .value{color:#5967f2;font-variant-numeric:tabular-nums;}
.control .sub{font-size:12px;color:#66748b;line-height:1.45;padding-bottom:8px;}
.control .form-group{margin-bottom:0;width:100%;}
.control .irs-single,.control .irs-from,.control .irs-to,.control .irs-min,.control .irs-max{display:none !important;}
.control .irs--shiny{height:34px;}
.control .irs--shiny .irs-line{top:18px;height:8px;border-radius:99px;background:#dfe6f2;border:0;}
.control .irs--shiny .irs-bar{top:18px;height:8px;background:var(--accent);border:0;}
.control .irs--shiny .irs-handle{top:11px;width:20px;height:20px;background:#fff;border:3px solid var(--accent);box-shadow:0 2px 8px rgba(89,103,242,.35);}
.chart-card{border:1px solid rgba(21,32,51,.08);border-radius:14px;background:#fff;padding:8px;overflow:hidden;box-shadow:0 8px 24px rgba(50,67,100,.05);}
.metricgrid{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:9px;margin:10px 0 4px;}
.metric{border:1px solid rgba(21,32,51,.08);background:#fff;border-radius:12px;padding:9px 11px;}
.mlabel{font-size:10px;color:#6a7890;text-transform:uppercase;letter-spacing:.06em;}
.mval{font-size:16px;font-weight:780;margin-top:3px;color:#152033;font-variant-numeric:tabular-nums;}
.mnote{font-size:10px;color:#7a879b;margin-top:2px;}
.footer{font-size:10.5px;color:#78869a;margin:8px 0 14px;}
.tbl-wrap{overflow:auto;border:1px solid var(--border);border-radius:14px;background:#fff;margin:.35rem 0 1rem;box-shadow:0 8px 24px rgba(50,67,100,.05);}
table.tbl{border-collapse:separate;border-spacing:0;width:100%;font-size:.84rem;font-variant-numeric:tabular-nums;}
table.tbl th{position:sticky;top:0;background:#eef2fa;color:#3a4860;font-weight:700;text-align:left;padding:.55rem .75rem;border-bottom:1px solid rgba(21,32,51,.12);white-space:nowrap;z-index:1;}
table.tbl td{padding:.48rem .75rem;border-bottom:1px solid rgba(21,32,51,.06);white-space:nowrap;}
table.tbl td.num{text-align:right;}
table.tbl th.num{text-align:right;}
table.tbl tr:last-child td{border-bottom:0;}
table.tbl tr:hover td{background:#f8faff;}
table.tbl tr.sel-row td{background:#eef2ff;font-weight:700;}
table.tbl tr.bench td{color:#5b6980;font-style:italic;}
table.tbl td.hi-aic{background:#e8f0ff !important;color:#1d4ed8;font-weight:700;}
table.tbl td.hi-cv{background:#e7f8f5 !important;color:#087f73;font-weight:700;}
.nav-tabs,.nav-pills{border:0;gap:.4rem;margin-bottom:.9rem;}
.nav-tabs .nav-link,.nav-pills .nav-link{border:1px solid var(--border) !important;border-radius:12px !important;background:rgba(255,255,255,.8);color:#44516a;font-weight:650;font-size:.9rem;padding:.45rem .95rem;}
.nav-tabs .nav-link.active,.nav-pills .nav-link.active{background:var(--accent) !important;color:#fff !important;border-color:var(--accent) !important;box-shadow:0 8px 20px rgba(89,103,242,.25);}
.form-select,select.form-control,select{border-radius:12px !important;border:1px solid rgba(21,32,51,.14) !important;background-color:#fff;color:#152033;padding:.45rem .75rem;}
.form-label,label.control-label{font-weight:650;font-size:.86rem;color:#44516a;}
.dataset-bar{display:flex;justify-content:space-between;align-items:center;gap:1rem;flex-wrap:wrap;margin:.2rem 0 .3rem;}
.btn-download{background:var(--accent);border:0;color:#fff;border-radius:12px;font-weight:650;font-size:.88rem;padding:.5rem 1rem;box-shadow:0 8px 20px rgba(89,103,242,.25);}
.btn-download:hover{background:#4a58e0;color:#fff;}
/* --- Slider ala lab interaktif: panel kontrol + grafik + metrik + interpretasi langsung --- */
.lv-lab{display:grid;grid-template-columns:310px 1fr;gap:18px;align-items:start;margin-top:12px;}
.lv-panel{border:1px solid var(--border);border-radius:16px;background:#fbfcff;padding:16px;position:sticky;top:14px;box-shadow:0 10px 28px rgba(50,67,100,.06);}
.lv-panel h3{margin:0 0 12px;font-size:1.05rem;font-weight:760;color:var(--accent);}
.lv-field{margin:13px 0;}
.lv-field label{display:flex;justify-content:space-between;gap:10px;font-size:.82rem;font-weight:800;color:#3f4b63;margin-bottom:5px;}
.lv-field label span:last-child{color:var(--accent);font-variant-numeric:tabular-nums;text-align:right;}
.lv-field input[type=range]{width:100%;accent-color:var(--accent);cursor:pointer;}
.lv-sub{font-size:.76rem;color:#66748b;line-height:1.45;}
.lv-stack{display:grid;gap:14px;min-width:0;}
.lv-metrics{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:9px;}
.lv-metric{border:1px solid var(--border);background:#fff;border-radius:11px;padding:10px;}
.lv-metric .lab{font-size:.70rem;text-transform:uppercase;color:#6a7890;font-weight:800;letter-spacing:.04em;}
.lv-metric .val{font-size:1.15rem;font-weight:850;color:#152033;margin-top:2px;font-variant-numeric:tabular-nums;}
.lv-metric .sub{font-size:.72rem;color:#7a879b;}
.lv-class{display:inline-block;padding:4px 9px;border-radius:999px;background:rgba(89,103,242,.10);color:#4b58d5;font-size:.76rem;font-weight:800;margin-top:6px;}
.lv-live{background:#f6f8ff;border:1px solid rgba(89,103,242,.18);border-radius:11px;padding:12px;margin:11px 0 0;font-size:.88rem;line-height:1.5;color:#334155;}
@media(max-width:980px){.lv-lab{grid-template-columns:1fr}.lv-panel{position:static}}
.pick-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:1rem;}
.err-box{max-width:760px;margin:12vh auto;padding:1.6rem 1.8rem;border-radius:22px;border:1px solid rgba(214,69,93,.25);background:#fff;box-shadow:0 24px 70px rgba(50,67,100,.12);}
.err-box h3{margin-top:0;color:#b4233c;}
/* --- Analysis Assistant --- */
.assistant-greeting{position:fixed;right:20px;bottom:104px;z-index:2147482999;max-width:300px;padding:.78rem .95rem;border:1px solid rgba(89,103,242,.16);border-radius:18px 18px 6px 18px;background:rgba(255,255,255,.98);box-shadow:0 16px 38px rgba(29,42,75,.16);color:#26344c;font-size:.82rem;line-height:1.45;animation:greetOut 3s ease forwards;pointer-events:none;}
.assistant-greeting strong{color:#5967f2;}
@keyframes greetOut{0%,72%{opacity:1;transform:translateY(0);visibility:visible;}100%{opacity:0;transform:translateY(8px);visibility:hidden;}}
#assistant-btn{position:fixed;right:20px;bottom:20px;z-index:2147483000;width:72px;height:72px;border-radius:50%;border:3px solid #fff;background:linear-gradient(135deg,#5967f2,#11a7a0);box-shadow:0 14px 34px rgba(41,55,110,.22),0 0 0 7px rgba(89,103,242,.09);font-size:2rem;line-height:1;padding:0;cursor:pointer;transition:transform .18s,box-shadow .18s;overflow:hidden;}
#assistant-btn:hover{transform:translateY(-4px) scale(1.05);box-shadow:0 18px 40px rgba(41,55,110,.28),0 0 0 9px rgba(89,103,242,.11);}
#assistant-btn img{width:100%;height:100%;object-fit:cover;display:block;}
#assistant-dot{position:fixed;right:21px;bottom:23px;z-index:2147483001;width:14px;height:14px;border-radius:50%;background:#21c77a;border:3px solid #fff;pointer-events:none;}
#assistant-panel{display:none;position:fixed;right:20px;bottom:104px;z-index:2147483002;width:min(380px,calc(100vw - 40px));max-height:calc(100vh - 140px);overflow:auto;padding:1rem 1.05rem;border:1px solid rgba(21,32,51,.10);border-radius:20px;background:#fff;box-shadow:0 24px 60px rgba(29,42,75,.18);}
#assistant-panel.open{display:block;}
.assistant-head{display:flex;align-items:center;gap:.75rem;margin-bottom:.55rem;}
.assistant-avatar{width:42px;height:42px;border-radius:50%;overflow:hidden;flex:none;background:linear-gradient(135deg,#5967f2,#11a7a0);border:2px solid #fff;box-shadow:0 6px 15px rgba(41,55,110,.16);display:flex;align-items:center;justify-content:center;font-size:1.4rem;}
.assistant-avatar img{width:100%;height:100%;object-fit:cover;}
.assistant-head-title{font-size:1rem;font-weight:780;color:#152033;}
.assistant-head-sub{font-size:.75rem;color:#6d7890;margin-top:.08rem;}
.assistant-question{margin-top:.55rem;padding:.7rem .85rem;border-radius:14px;background:#f0f4ff;border:1px solid rgba(89,103,242,.12);color:#44516a;font-size:.83rem;line-height:1.4;}
.assistant-answer{margin-top:.65rem;padding:.85rem .95rem;border-radius:16px 16px 16px 5px;background:linear-gradient(135deg,#5967f2,#6975ef);color:#fff;box-shadow:0 10px 22px rgba(89,103,242,.18);font-size:.84rem;line-height:1.52;}
.assistant-answer b{color:#fff;}
.assistant-caption{color:#718096;font-size:.70rem;margin-top:.55rem;}
@media(max-width:900px){.card-row{grid-template-columns:repeat(2,minmax(0,1fr));}.controls{grid-template-columns:1fr;}.pick-grid{grid-template-columns:1fr;}.hero-title{font-size:1.6rem;}}
"

ASSISTANT_JS <- "
document.addEventListener('click', function(e){
  var b=document.getElementById('assistant-btn'), p=document.getElementById('assistant-panel');
  if(!b||!p) return;
  if(b.contains(e.target)){ p.classList.toggle('open'); }
  else if(!p.contains(e.target)){ p.classList.remove('open'); }
});
"

# -----------------------------------------------------------------------------
# Fungsi bantu tampilan
# -----------------------------------------------------------------------------
`%||%` <- function(a, b) if (is.null(a)) b else a

fmt_num <- function(x, d = 4) {
  ifelse(is.na(x) | !is.finite(x), "\u2014", formatC(x, format = "f", digits = d, big.mark = ""))
}
fmt_int <- function(x) format(x, big.mark = ".", decimal.mark = ",", scientific = FALSE)

hero <- function(title, sub) div(class = "hero", div(class = "hero-title", title), div(class = "hero-sub", sub))
section_title <- function(txt) div(class = "section-title", txt)
note_box <- function(..., warn = FALSE) div(class = paste("note", if (warn) "warn"), ...)

metric_card <- function(label, value, note = "") {
  div(class = "metric-card", div(class = "metric-label", label),
      div(class = "metric-value", value), div(class = "metric-note", note))
}
card_row <- function(...) div(class = "card-row", ...)

metric_grid <- function(items) {
  div(class = "metricgrid", lapply(items, function(m) {
    div(class = "metric", div(class = "mlabel", m[[1]]), div(class = "mval", m[[2]]),
        div(class = "mnote", m[[3]] %||% ""))
  }))
}

# Tabel HTML dengan penyorotan nilai minimum (biru = AICc, hijau = CV_RMSE)
html_table <- function(df, digits = 4, col_digits = NULL, hi_aicc = NULL, hi_cv = NULL,
                       row_min = NULL, sel = NULL, bench = NULL, elig = NULL, max_h = NULL) {
  df <- as.data.frame(df, stringsAsFactors = FALSE, check.names = FALSE)
  nr <- nrow(df); nc <- ncol(df)
  if (nr == 0) return(div(class = "note", "Tidak ada data."))
  elig <- elig %||% rep(TRUE, nr)
  cls <- matrix("", nr, nc, dimnames = list(NULL, names(df)))
  mark <- function(cn, klass) {
    v <- suppressWarnings(as.numeric(df[[cn]])); ok <- is.finite(v) & elig
    if (any(ok)) cls[which(ok & abs(v - min(v[ok])) < 1e-9), cn] <<- klass
  }
  for (cn in intersect(hi_aicc, names(df))) mark(cn, "hi-aic")
  for (cn in intersect(hi_cv, names(df))) mark(cn, "hi-cv")
  if (!is.null(row_min)) {
    row_min <- intersect(row_min, names(df))
    for (r in seq_len(nr)) {
      v <- suppressWarnings(as.numeric(unlist(df[r, row_min])))
      if (any(is.finite(v))) cls[r, row_min[which(is.finite(v) & abs(v - min(v[is.finite(v)])) < 1e-9)]] <- "hi-aic"
    }
  }
  is_num <- vapply(df, is.numeric, logical(1))
  head <- tags$tr(lapply(seq_len(nc), function(j) tags$th(class = if (is_num[j]) "num", names(df)[j])))
  body <- lapply(seq_len(nr), function(i) {
    tags$tr(class = paste(if (isTRUE(sel[i])) "sel-row", if (isTRUE(bench[i])) "bench"),
            lapply(seq_len(nc), function(j) {
              x <- df[[j]][i]
              d <- if (!is.null(col_digits) && names(df)[j] %in% names(col_digits)) col_digits[[names(df)[j]]] else digits
              txt <- if (is.logical(x)) (if (is.na(x)) "\u2014" else if (x) "Ya" else "Tidak")
              else if (is.numeric(x)) fmt_num(x, d) else if (is.na(x)) "\u2014" else as.character(x)
              tags$td(class = paste(if (is_num[j]) "num", cls[i, j]), txt)
            }))
  })
  div(class = "tbl-wrap", style = if (!is.null(max_h)) paste0("max-height:", max_h, ";"),
      tags$table(class = "tbl", tags$thead(head), tags$tbody(body)))
}

# Tema plotly yang konsisten
pl_theme <- function(p, height = 360, title = NULL, ...) {
  p %>% layout(height = height,
               title = if (!is.null(title)) list(text = title, x = 0.01, xanchor = "left", font = list(size = 14, color = "#344054")),
               paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
               font = list(color = "#25334a", size = 12),
               margin = list(l = 62, r = 20, t = if (is.null(title)) 30 else 52, b = 52),
               legend = list(orientation = "h", y = 1.1, x = 0), ...) %>%
    config(displaylogo = FALSE, responsive = TRUE, modeBarButtonsToRemove = c("lasso2d", "select2d"))
}
axis_style <- list(gridcolor = "#e8edf5", zerolinecolor = "#c9d3e3", linecolor = "#9aa7ba")

# -----------------------------------------------------------------------------
# Konstanta & objek turunan dari hasil tersimpan
# -----------------------------------------------------------------------------
if (!is.null(PAYLOAD)) {
  META <- PAYLOAD$meta; SUMM <- PAYLOAD$summary; DETAIL <- PAYLOAD$detail
  SHEETS <- META$sheets; FEATURES <- META$features
  ALL_MODELS <- META$models; STAT_MODELS <- META$stat_models; RF_NAME <- META$rf_name
  GAM_NAME <- grep("GAM", STAT_MODELS, value = TRUE)[1]
  POLY_MODELS <- setdiff(STAT_MODELS, GAM_NAME)
  N_TEST <- META$n_test
  short_model <- function(x) sub("^(M[0-9]+).*$", "\\1", ifelse(x == RF_NAME, "RF", x))
  MODEL_COL <- setNames(c("#8a97ad", "#5967f2", "#11a7a0", "#7c5cd6", "#e48620", "#d6455d")[seq_along(ALL_MODELS)], ALL_MODELS)
  STAB <- SUMM$stab_tab
  
  # scorecard: tidak ada penjumlahan rank; prioritas hierarkis seperti App.py
  build_scorecard <- function(stab) {
    recs <- list()
    for (sh in SHEETS) {
      st <- stab[stab$Sheet == sh & stab$Model %in% STAT_MODELS, ]
      a_min <- min(st$AICc); c_min <- min(st$CV_RMSE)
      for (i in seq_len(nrow(st))) {
        a <- abs(st$AICc[i] - a_min) < 1e-9; cv <- abs(st$CV_RMSE[i] - c_min) < 1e-9
        recs[[length(recs) + 1]] <- data.frame(Sheet = sh, Model = st$Model[i], A = a, C = cv, B = a & cv)
      }
    }
    fl <- do.call(rbind, recs); ns <- length(SHEETS)
    sc <- do.call(rbind, lapply(STAT_MODELS, function(m) {
      t <- fl[fl$Model == m, ]
      data.frame(Model = m, `AICc Best (sheet)` = sum(t$A), `CV Best (sheet)` = sum(t$C),
                 `AICc & CV Best (sheet)` = sum(t$B), `AICc Best (%)` = 100 * sum(t$A) / ns,
                 `CV Best (%)` = 100 * sum(t$C) / ns, `AICc & CV Best (%)` = 100 * sum(t$B) / ns,
                 check.names = FALSE)
    }))
    sc <- sc[order(-sc[["AICc & CV Best (sheet)"]], -sc[["AICc Best (sheet)"]], -sc[["CV Best (sheet)"]]), ]
    rownames(sc) <- NULL
    top <- sc[1, ]
    sc$Selected <- sc[["AICc & CV Best (sheet)"]] == top[["AICc & CV Best (sheet)"]] &
      sc[["AICc Best (sheet)"]] == top[["AICc Best (sheet)"]] & sc[["CV Best (sheet)"]] == top[["CV Best (sheet)"]]
    sc
  }
  SCORECARD <- build_scorecard(STAB)
  
  # model terbaik per sheet: AICc & CV sepakat -> model itu; jika tidak -> minimum CV
  best_model_of <- function(sh) {
    p <- PAYLOAD$sheets[[sh]]$pick
    list(model = unname(p[["CV"]]), agree = identical(unname(p[["AICc"]]), unname(p[["CV"]])),
         aicc_pick = unname(p[["AICc"]]))
  }
}

# -----------------------------------------------------------------------------
# Modul slider "dua grafik" (Grafik 1 = parameter terbaik CV, Grafik 2 = slider)
# -----------------------------------------------------------------------------
# Logika slider mengikuti lab interaktif: nilai slider dibaca -> label nilai diperbarui ->
# metrik dihitung ulang -> grafik SVG digambar ulang -> kartu metrik, label kelas, dan teks
# interpretasi ikut berubah. Semuanya berjalan di browser (oninput) tanpa memanggil server,
# sehingga responsnya instan. Data yang dipakai hanya hasil tersimpan dari R.Rmd.
LIVE_JS <- r"---(
(function(){
var UID="__UID__", D=__DATA__;
var ST=(window.__lvState=window.__lvState||{});
function g(s){return document.getElementById(UID+"_"+s);}
function f(v,d){return (v===null||v===undefined||!isFinite(v))?"\u2014":Number(v).toFixed(d);}
function loc(n){return Number(n).toLocaleString("id-ID");}
function rng(arrs){var lo=Infinity,hi=-Infinity;arrs.forEach(function(a){for(var i=0;i<a.length;i++){if(a[i]<lo)lo=a[i];if(a[i]>hi)hi=a[i];}});return [lo,hi];}
function met(it,n){
  var Y=D.Y,P=it.pred,m=0,i;
  for(i=0;i<n;i++)m+=Y[i]; m/=n;
  var sse=0,sst=0;
  for(i=0;i<n;i++){var e=Y[i]-P[i];sse+=e*e;sst+=(Y[i]-m)*(Y[i]-m);}
  return {rmse:Math.sqrt(sse/n), r2:sst>0?1-sse/sst:NaN};
}
function draw(it,ref,n){
  var svg=g("svg"),W=900,H=430,L=62,R=22,T=26,B=54,i;
  var xs=D.X.slice(0,n),ys=D.Y.slice(0,n);
  var rx=rng([xs,D.grid]),ry=rng([ys,it.line,ref.line]);
  var xmin=rx[0],xmax=rx[1],ymin=ry[0],ymax=ry[1],dx=(xmax-xmin)||1,dy=(ymax-ymin)||1;
  xmin-=.06*dx;xmax+=.06*dx;ymin-=.08*dy;ymax+=.08*dy;
  function sx(x){return L+(x-xmin)/(xmax-xmin)*(W-L-R);}
  function sy(y){return H-B-(y-ymin)/(ymax-ymin)*(H-T-B);}
  function pl(line){return D.grid.map(function(v,k){return sx(v).toFixed(1)+","+sy(line[k]).toFixed(1);}).join(" ");}
  var h="";
  for(i=0;i<5;i++){var gy=T+i*(H-T-B)/4,val=ymax-i*(ymax-ymin)/4;
    h+='<line x1="'+L+'" x2="'+(W-R)+'" y1="'+gy+'" y2="'+gy+'" stroke="#e8edf5"/><text x="'+(L-9)+'" y="'+(gy+4)+'" text-anchor="end" font-size="10" fill="#718096">'+val.toFixed(1)+'</text>';}
  for(i=0;i<5;i++){var gx=L+i*(W-L-R)/4,xv=xmin+i*(xmax-xmin)/4;
    h+='<text x="'+gx+'" y="'+(H-B+17)+'" text-anchor="middle" font-size="10" fill="#718096">'+xv.toFixed(1)+'</text>';}
  h+='<line x1="'+L+'" x2="'+(W-R)+'" y1="'+(H-B)+'" y2="'+(H-B)+'" stroke="#9aa7ba"/><line x1="'+L+'" x2="'+L+'" y1="'+T+'" y2="'+(H-B)+'" stroke="#9aa7ba"/>';
  var r=n>1200?2.1:2.8;
  for(i=0;i<n;i++)h+='<circle cx="'+sx(xs[i]).toFixed(1)+'" cy="'+sy(ys[i]).toFixed(1)+'" r="'+r+'" fill="#7b8799" opacity=".45"/>';
  var showRef=(!D.single&&ref!==it);
  if(showRef)h+='<polyline points="'+pl(ref.line)+'" fill="none" stroke="#2c5aa0" stroke-width="3" stroke-dasharray="8 5"/>';
  h+='<polyline points="'+pl(it.line)+'" fill="none" stroke="#176b4b" stroke-width="3.4"/>';
  var lx=W-R-285,ly=T+4,rows=[["#7b8799","Data test (N = "+loc(n)+")"],["#176b4b","Model aktif: "+it.label]];
  if(showRef)rows.push(["#2c5aa0","Terbaik CV: "+ref.label]);
  h+='<rect x="'+(lx-8)+'" y="'+ly+'" width="290" height="'+(rows.length*19+8)+'" rx="8" fill="#fff" opacity=".88"/>';
  rows.forEach(function(rw,k){h+='<text x="'+lx+'" y="'+(ly+19+k*19)+'" font-size="12" fill="'+rw[0]+'">'+rw[1]+'</text>';});
  h+='<text x="'+((L+W-R)/2)+'" y="'+(H-12)+'" text-anchor="middle" font-size="11" fill="#607089">'+D.feature+'</text>';
  h+='<text x="17" y="'+((T+H-B)/2)+'" transform="rotate(-90 17 '+((T+H-B)/2)+')" text-anchor="middle" font-size="11" fill="#607089">PE (MW)</text>';
  svg.innerHTML=h;
}
function update(){
  var si=g("idx"),sn=g("n"),n=Math.min(+sn.value,D.Y.length);
  var i=si?(+si.value-1):D.init,it=D.items[i],ref=D.items[D.ref];
  ST[UID]={idx:si?+si.value:null,n:n};
  g("vn").textContent=loc(n);
  if(si)g("vp").textContent=it.short;
  var m=met(it,n),mr=met(ref,n),dcv=(it.cv-ref.cv)/ref.cv*100,amin=Infinity;
  D.items.forEach(function(z){if(z.aicc!==null&&z.aicc<amin)amin=z.aicc;});
  var cards=[
    ["AICc",f(it.aicc,2),it.aicc===null?"tidak ada likelihood":(it.aicc===amin?"minimum di kelompok":"\u0394 "+f(it.aicc-amin,2)+" dari minimum")],
    ["CV RMSE",f(it.cv,4),"model aktif"],
    ["Test RMSE",f(m.rmse,4),"N = "+loc(n)],
    ["Test R\u00b2",f(m.r2,4),"N = "+loc(n)],
    [it.xl,it.xv,"parameter aktif"]];
  if(!D.single)cards.push(["\u0394 CV vs terbaik",(dcv>=0?"+":"")+f(dcv,2)+"%","terhadap "+ref.short]);
  g("cards").innerHTML=cards.map(function(c){return '<div class="lv-metric"><div class="lab">'+c[0]+'</div><div class="val">'+c[1]+'</div><div class="sub">'+c[2]+'</div></div>';}).join("");
  g("cls").textContent=it.cls;
  var t='<b>Interpretasi saat ini:</b> <b>'+it.label+'</b> ('+it.cls+') memiliki CV_RMSE '+f(it.cv,4)+' MW';
  if(!D.single){
    if(it===ref)t+=' dan merupakan <b>model terbaik menurut CV</b> pada kelompok ini.';
    else t+=', '+(dcv>0?'lebih tinggi ':'lebih rendah ')+f(Math.abs(dcv),2)+'% dibanding '+ref.label+' (terbaik CV, '+f(ref.cv,4)+').';
  } else t+='.';
  if(it.aicc!==null)t+=' AICc = '+f(it.aicc,2)+'.';
  t+=' Pada '+loc(n)+' data test, Test RMSE = <b>'+f(m.rmse,4)+'</b> MW'+((!D.single&&it!==ref)?' (model terbaik CV: '+f(mr.rmse,4)+')':'')+' dan R\u00b2 = '+f(m.r2,4)+'. '+it.note;
  g("live").innerHTML=t;
  draw(it,ref,n);
}
var si0=g("idx"),sn0=g("n"),s0=ST[UID];
if(s0){if(si0&&s0.idx!==null)si0.value=s0.idx; sn0.value=s0.n;}
if(si0)si0.addEventListener("input",update);
sn0.addEventListener("input",update);
update();
})();
)---"

live_widget <- function(uid, items, X, Y, grid, feature, ptitle = NULL, init_idx = 1, ref_idx = 1, tips = NULL) {
  nmax <- length(Y)
  payload <- list(
    items = lapply(items, function(z) list(label = z$label, short = z$short, aicc = z$aicc, cv = z$cv,
                                           xl = z$extra[[1]], xv = z$extra[[2]], cls = z$cls, note = z$note,
                                           pred = round(z$pred, 3), line = round(z$line, 3))),
    X = round(X, 3), Y = round(Y, 3), grid = round(grid, 3), feature = feature,
    ref = ref_idx - 1, init = init_idx - 1, single = length(items) == 1)
  json <- as.character(jsonlite::toJSON(payload, auto_unbox = TRUE, na = "null", digits = NA))
  js <- gsub("__UID__", uid, gsub("__DATA__", json, LIVE_JS, fixed = TRUE), fixed = TRUE)
  id <- function(x) paste0(uid, "_", x)
  tagList(
    div(class = "lv-lab",
        div(class = "lv-panel",
            tags$h3("\U0001F39B\uFE0F Kontrol"),
            if (!is.null(ptitle))
              div(class = "lv-field", tags$label(span(ptitle), span(id = id("vp"))),
                  tags$input(id = id("idx"), type = "range", min = 1, max = length(items), step = 1, value = init_idx)),
            div(class = "lv-field", tags$label(span("Jumlah data test"), span(id = id("vn"))),
                tags$input(id = id("n"), type = "range", min = 10, max = nmax, step = 1, value = nmax)),
            div(class = "lv-field", tags$label(span("Prediktor"), span(feature)),
                div(class = "lv-sub", "Prediktor lain tetap pada median data train.")),
            if (!is.null(tips)) div(class = "lv-live", HTML(tips)),
            span(class = "lv-class", id = id("cls"))),
        div(class = "lv-stack",
            div(class = "chart-card", HTML(sprintf('<svg id="%s" viewBox="0 0 900 430" style="width:100%%;height:auto;display:block"></svg>', id("svg")))),
            div(class = "lv-metrics", id = id("cards")),
            div(class = "lv-live", id = id("live")))),
    tags$script(HTML(js)))
}

live_ui <- function(id, param_title, n_items, n_test, init_idx, footer) {
  ns <- NS(id)
  tagList(
    div(class = "section-label", "Grafik 1 \u00b7 Parameter model terbaik (CV)"),
    div(class = "chart-card", plotlyOutput(ns("best_plot"), height = "400px")),
    uiOutput(ns("best_cards")),
    div(class = "section-label", style = "margin-top:14px",
        paste0("Grafik 2 \u00b7 Ubah ", tolower(param_title), " dan jumlah data")),
    uiOutput(ns("widget")),
    div(class = "footer", footer)
  )
}

live_server <- function(id, items, feature, sheet_data, sheet_id, plot_title, cards_best,
                        ptitle, tips, short_fn, extra_fn, cls_fn, note_fn) {
  moduleServer(id, function(input, output, session) {
    best_idx <- reactive(which.min(vapply(items(), function(z) z$cv, numeric(1))))
    metrics <- function(it, n) {
      y <- sheet_data()$y_test[seq_len(n)]; p <- it$pred[seq_len(n)]
      sse <- sum((y - p)^2); sst <- sum((y - mean(y))^2)
      c(rmse = sqrt(sse / n), r2 = if (sst > 0) 1 - sse / sst else NA_real_)
    }
    output$best_plot <- renderPlotly({
      it <- items()[[best_idx()]]; sd <- sheet_data(); f <- feature(); n <- length(sd$y_test)
      plot_ly() %>%
        add_trace(type = "scattergl", mode = "markers", x = sd$X_test[[f]], y = sd$y_test,
                  marker = list(size = 5, color = "#8090a7", opacity = .42), name = "Data test", hoverinfo = "skip") %>%
        add_trace(type = "scatter", mode = "lines", x = sd$grids[[f]], y = it$lines[[f]],
                  line = list(color = "#5967f2", width = 3.2), name = "Prediksi model") %>%
        pl_theme(height = 400, title = plot_title(it),
                 xaxis = c(list(title = f), axis_style), yaxis = c(list(title = "PE (MW)"), axis_style))
    })
    output$best_cards <- renderUI({
      it <- items()[[best_idx()]]; cards_best(it, metrics(it, length(sheet_data()$y_test)))
    })
    output$widget <- renderUI({
      it <- items(); sd <- sheet_data(); f <- feature()
      its <- lapply(it, function(z) list(label = z$label, short = short_fn(z), aicc = z$aicc, cv = z$cv,
                                         extra = extra_fn(z), cls = cls_fn(z), note = note_fn(z),
                                         pred = z$pred, line = z$lines[[f]]))
      live_widget(uid = paste0(id, "_", gsub("[^A-Za-z0-9]", "", sheet_id())), items = its,
                  X = sd$X_test[[f]], Y = sd$y_test, grid = sd$grids[[f]], feature = f,
                  ptitle = ptitle, init_idx = best_idx(), ref_idx = best_idx(), tips = tips)
    })
  })
}

# -----------------------------------------------------------------------------
# Analysis Assistant (aturan sederhana; hanya memakai hasil yang tersimpan)
# -----------------------------------------------------------------------------
ASSISTANT_QUESTIONS <- c(
  "Model statistik dengan CV_RMSE terendah apa?",
  "Model statistik dengan AICc terendah apa?",
  "Apakah AICc dan CV memilih model yang sama?",
  "Bagaimana hasil Polinomial dan interaksi (M0\u2013M3)?",
  "Bagaimana hasil GAM?",
  "Bagaimana Random Forest dibanding GAM?",
  "Berapa Test RMSE dan Test R\u00b2 model CV terpilih?",
  "Apakah pengacakan antar-sheet mengubah AICc dan CV?",
  "Berapa jumlah data train, test, dan fold CV?",
  "Apa ringkasan hasil analisis?"
)

md_inline <- function(x) {
  x <- htmltools::htmlEscape(x)
  x <- gsub("\\*\\*(.+?)\\*\\*", "<b>\\1</b>", x)
  gsub("\n", "<br>", x)
}

assistant_answer <- function(q, sheet) {
  if (is.null(PAYLOAD)) return("Hasil analisis belum tersedia.")
  sd <- PAYLOAD$sheets[[sheet]]; tb <- sd$table
  st <- tb[tb$Model %in% STAT_MODELS, ]; rf <- tb[tb$Model == RF_NAME, ]
  b_cv <- st[which.min(st$CV_RMSE), ]; b_aic <- st[which.min(st$AICc), ]
  f4 <- function(x) fmt_num(x, 4); f2 <- function(x) fmt_num(x, 2)
  gam <- tb[tb$Model == GAM_NAME, ]
  switch(match(q, ASSISTANT_QUESTIONS),
         sprintf("Pada %s, model statistik dengan CV_RMSE terendah adalah **%s**. CV_RMSE = %s MW, AICc = %s, Test_RMSE = %s, dan Test R\u00b2 = %s. Random Forest (benchmark) memiliki CV_RMSE %s.",
                 sheet, b_cv$Model, f4(b_cv$CV_RMSE), f2(b_cv$AICc), f4(b_cv$Test_RMSE), f4(b_cv$Test_R2), f4(rf$CV_RMSE)),
         sprintf("Pada %s, AICc terendah dimiliki **%s** dengan AICc = %s (k = %d). Bobot Akaike-nya %s. Random Forest tidak punya likelihood sehingga tidak dihitung AICc-nya.",
                 sheet, b_aic$Model, f2(b_aic$AICc), as.integer(b_aic$k), fmt_num(b_aic$w_Akaike, 3)),
         if (identical(b_aic$Model, b_cv$Model))
           sprintf("Ya. Pada %s, AICc dan CV_RMSE sama-sama memilih **%s**. Secara keseluruhan, pemenang AICc dan CV sama pada %d dari %d pengacakan.", sheet, b_cv$Model, SUMM$n_agree, SUMM$n_sheet)
         else
           sprintf("Tidak identik pada %s. AICc memilih **%s** (AICc = %s), sedangkan CV_RMSE memilih **%s** (CV_RMSE = %s). Lintas pengacakan, keduanya sepakat pada %d dari %d sheet.",
                   sheet, b_aic$Model, f2(b_aic$AICc), b_cv$Model, f4(b_cv$CV_RMSE), SUMM$n_agree, SUMM$n_sheet),
         paste0("Hasil model polinomial/interaksi pada ", sheet, ":\n",
                paste(vapply(POLY_MODELS, function(m) { r <- tb[tb$Model == m, ]
                sprintf("\u2022 %s: AICc = %s, CV_RMSE = %s, Test_RMSE = %s", m, f2(r$AICc), f4(r$CV_RMSE), f4(r$Test_RMSE)) }, ""), collapse = "\n")),
         sprintf("GAM (%s) pada %s: AICc = %s (k = %s), CV_RMSE = %s, Test_RMSE = %s, Test R\u00b2 = %s. Pada grid faktor penalti, CV terbaik diperoleh pada sp \u00d7 10^%d.",
                 GAM_NAME, sheet, f2(gam$AICc), fmt_num(gam$k, 1), f4(gam$CV_RMSE), f4(gam$Test_RMSE), f4(gam$Test_R2),
                 sd$gam_grid[[which.min(vapply(sd$gam_grid, function(z) z$cv, 0))]]$exponent),
         sprintf("Pada %s, Random Forest memiliki CV_RMSE %s dan Test_RMSE %s (mtry akhir = %s, OOB RMSE = %s), sedangkan GAM memiliki CV_RMSE %s dan Test_RMSE %s. %s Random Forest hanya benchmark prediksi; ia tidak memberi koefisien, CI, atau uji hipotesis.",
                 sheet, f4(rf$CV_RMSE), f4(rf$Test_RMSE), rf$RF_mtry_final, f4(rf$RF_OOB_RMSE), f4(gam$CV_RMSE), f4(gam$Test_RMSE),
                 if (rf$CV_RMSE < gam$CV_RMSE) "RF lebih akurat daripada GAM, sehingga masih ada struktur yang belum tertangkap model statistik." else "RF tidak lebih akurat daripada GAM pada sheet ini."),
         sprintf("Untuk model statistik terpilih menurut CV pada %s (**%s**): Test_RMSE = %s MW, Test R\u00b2 = %s, Test_MAE = %s, bias rata-rata = %s MW.",
                 sheet, b_cv$Model, f4(b_cv$Test_RMSE), f4(b_cv$Test_R2), f4(b_cv$Test_MAE), f4(b_cv$Test_Bias)),
         {
           rng <- function(col) { v <- tapply(STAB[[col]], STAB$Model, function(z) c(min(z), max(z), sd(z)))
           vapply(names(v), function(m) sprintf("\u2022 %s: %s\u2013%s (SD %s)", m, fmt_num(v[[m]][1], 3), fmt_num(v[[m]][2], 3), fmt_num(v[[m]][3], 3)), "") }
           paste0("Kelima sheet berisi observasi yang sama dengan urutan baris berbeda, sehingga variasi di bawah ini mengukur sensitivitas terhadap pembagian data, bukan variasi antar-populasi.\n\n**CV_RMSE** per model (rentang, SD):\n",
                  paste(rng("CV_RMSE")[STAT_MODELS], collapse = "\n"),
                  "\n\nPemenang AICc dan CV sama pada ", SUMM$n_agree, " dari ", SUMM$n_sheet, " sheet.")
         },
         sprintf("Konfigurasi hasil aktif: total observasi = %s; train = %s; test = %s; test_size = %.2f; CV = %d-fold; seed = %d; bootstrap B = %d; Random Forest %d pohon (CV) dan %d pohon (akhir).",
                 fmt_int(META$n_total), fmt_int(META$n_train), fmt_int(META$n_test), META$test_size, META$k_folds, META$seed, META$b_boot, META$rf_trees_cv, META$rf_trees_final),
         sprintf("Ringkasan %s: CV_RMSE terendah di antara model statistik dicapai **%s** (%s MW); AICc terendah dicapai **%s** (%s). Model CV terpilih memiliki Test_RMSE %s dan R\u00b2 %s. Random Forest (benchmark) memiliki CV_RMSE %s. AICc dan CV sepakat pada %d dari %d pengacakan.",
                 sheet, b_cv$Model, f4(b_cv$CV_RMSE), b_aic$Model, f2(b_aic$AICc), f4(b_cv$Test_RMSE), f4(b_cv$Test_R2), f4(rf$CV_RMSE), SUMM$n_agree, SUMM$n_sheet),
         "Pertanyaan tersebut belum tersedia."
  )
}

assistant_ui <- function() {
  has_avatar <- file.exists(file.path("www", "robot_avatar_small.png"))
  avatar <- if (has_avatar) tags$img(src = "robot_avatar_small.png", alt = "Analysis Assistant") else "\U0001F916"
  tagList(
    div(class = "assistant-greeting",
        tags$strong("Halo! \U0001F44B Saya Analysis Assistant."), tags$br(),
        "Saya bisa membantu menjelaskan hasil AICc, CV, polinomial, GAM, dan Random Forest. Klik robot di bawah untuk memilih pertanyaan."),
    tags$button(id = "assistant-btn", type = "button", title = "Analysis Assistant", avatar),
    div(id = "assistant-dot"),
    div(id = "assistant-panel",
        div(class = "assistant-head", div(class = "assistant-avatar", avatar),
            div(div(class = "assistant-head-title", "Analysis Assistant"),
                div(class = "assistant-head-sub", "Tanya berdasarkan hasil analisis aktif"))),
        selectInput("assistant_q", NULL, choices = ASSISTANT_QUESTIONS, selectize = FALSE, width = "100%"),
        uiOutput("assistant_out"),
        div(class = "assistant-caption", "Jawaban diambil dari hasil analisis tersimpan (R.Rmd)."))
  )
}

# -----------------------------------------------------------------------------
# UI
# -----------------------------------------------------------------------------
NAV_CHOICES <- c("01 \u00b7 Eksplorasi Data" = "p1", "02 \u00b7 Analisis Model" = "p2",
                 "03 \u00b7 Evaluasi & Perbandingan" = "p3", "04 \u00b7 Diagnostik & Inferensi" = "p4")

sel_input <- function(id, label, choices, selected = NULL) {
  selectInput(id, label, choices = choices, selected = selected, selectize = FALSE, width = "100%")
}

if (is.null(PAYLOAD)) {
  ui <- fluidPage(tags$head(tags$style(HTML(APP_CSS)), tags$title(APP_TITLE)),
                  div(class = "err-box", h3("Hasil analisis belum tersedia"), p(LOAD_ERROR),
                      p(class = "small-muted", "Dashboard ini tidak menghitung model apa pun; seluruh angka dan grafik berasal dari berkas hasil R.Rmd.")))
} else {
  first_sheet <- SHEETS[1]
  fs <- PAYLOAD$sheets[[first_sheet]]
  init_best <- list(
    poly = which.min(vapply(POLY_MODELS, function(m) fs$table$CV_RMSE[fs$table$Model == m], 0)),
    gam = which.min(vapply(fs$gam_grid, function(z) z$cv, 0)),
    rf = which.min(vapply(fs$rf_grid, function(z) z$cv, 0)))
  
  page1 <- conditionalPanel("input.page == 'p1'",
                            hero("01 \u00b7 Eksplorasi Data", "Eksplorasi distribusi, kualitas data, korelasi, dan outlier."),
                            sel_input("p1_sheet", "Pilih sheet", SHEETS),
                            uiOutput("p1_cards"),
                            section_title("Dataset"),
                            div(class = "dataset-bar",
                                div(class = "caption-line", style = "margin:0;", uiOutput("p1_data_caption", inline = TRUE)),
                                downloadButton("p1_download", "Download full dataset (CSV)", class = "btn-download")),
                            uiOutput("p1_data_tbl"),
                            section_title("Statistik deskriptif"), uiOutput("p1_desc"),
                            section_title("Distribusi"), div(class = "chart-card", plotlyOutput("p1_hist", height = "500px")),
                            section_title("Korelasi dan hubungan prediktor terhadap PE"),
                            div(class = "chart-card", plotlyOutput("p1_corr", height = "460px")),
                            div(style = "height:.9rem"),
                            div(class = "chart-card", plotlyOutput("p1_scatter", height = "380px")),
                            div(class = "caption-line", "Garis putus-putus abu-abu = linear; garis oranye = smooth GAM. Selisih keduanya menunjukkan indikasi non-linearitas."),
                            section_title("Multikolinearitas (VIF)"), uiOutput("p1_vif"),
                            section_title("Outlier IQR"), uiOutput("p1_outlier"),
                            note_box(tags$b("Catatan:"), " duplikat dipertahankan karena data berupa rata-rata per jam dengan presisi terbatas. ",
                                     "Outlier IQR pada AP dan RH dipertahankan karena nilainya masih dalam rentang fisik yang wajar; pengaruhnya diperiksa lewat Cook's distance (halaman 04).")
  )
  
  page2 <- conditionalPanel("input.page == 'p2'",
                            hero("02 \u00b7 Analisis Model", "Model selection mengikuti R.Rmd: polinomial dan interaksi (M0\u2013M3), GAM (M4), dan Random Forest sebagai benchmark prediksi, dinilai dengan AICc dan cross-validation."),
                            sel_input("p2_sheet", "Pilih sheet analisis", SHEETS),
                            uiOutput("p2_caption"),
                            sel_input("p2_feature", "Prediktor grafik", FEATURES),
                            tabsetPanel(id = "p2_tabs", type = "pills",
                                        tabPanel("Polinomial & Interaksi",
                                                 div(style = "height:.4rem"), tags$b("Perbandingan parameter: AICc dan CV_RMSE"), uiOutput("p2_poly_tbl"),
                                                 live_ui("poly", "Model kandidat", length(POLY_MODELS), N_TEST, init_best$poly,
                                                         "Grafik 1 memakai model dengan CV_RMSE terendah. Grafik 2 memperbarui model kandidat dan jumlah data test secara langsung. Kurva dihitung dengan prediktor lain pada median data latih.")),
                                        tabPanel("GAM",
                                                 div(style = "height:.4rem"), tags$b("Perbandingan parameter: faktor penalti (sp) GAM"), uiOutput("p2_gam_tbl"),
                                                 note_box("Grid ini mengalikan smoothing parameter hasil REML dengan faktor 10^e. CV pada grid memakai sp tetap pada seluruh fold, sehingga berbeda dari CV_RMSE M4 pada tabel utama yang mengestimasi ulang sp (REML) di setiap fold. AICc pada grid juga memakai edf biasa (sp tetap, tanpa koreksi ketidakpastian sp), sedangkan AICc M4 pada tabel utama memakai edf terkoreksi dari logLik() mgcv, sehingga kedua angka pada faktor 10^0 sedikit berbeda."),
                                                 live_ui("gam", "log10(faktor sp)", length(fs$gam_grid), N_TEST, init_best$gam,
                                                         "AICc, CV RMSE, Test RMSE, dan Test R\u00b2 pada Grafik 2 diperbarui sesuai faktor penalti dan jumlah data test yang aktif.")),
                                        tabPanel("Random Forest",
                                                 div(style = "height:.4rem"), tags$b("Perbandingan parameter: mtry Random Forest (benchmark)"), uiOutput("p2_rf_tbl"),
                                                 note_box("Random Forest tidak memiliki likelihood sehingga tidak ada AICc. CV pada grid memakai mtry tetap; mtry akhir pada analisis utama dipilih lewat OOB error."),
                                                 live_ui("rf", "mtry", length(fs$rf_grid), N_TEST, init_best$rf,
                                                         "Random Forest hanya dibandingkan dari sisi akurasi prediksi (CV dan data uji). Grafik 2 memperbarui mtry dan jumlah data test secara langsung."))
                            ),
                            section_title("Ringkasan test set"), uiOutput("p2_summary"),
                            div(class = "caption-line", "Biru = AICc minimum (model statistik M0\u2013M4); hijau = CV_RMSE minimum (model statistik). Baris miring = benchmark.")
  )
  
  page3 <- conditionalPanel("input.page == 'p3'",
                            hero("03 \u00b7 Evaluasi & Perbandingan", "Perbandingan lintas lima sheet, kestabilan akibat pengacakan baris, dan identifikasi model berdasarkan AICc dan CV."),
                            uiOutput("p3_cards"),
                            section_title("Scorecard pemilihan model"), uiOutput("p3_score"),
                            note_box(tags$b("Logika scorecard:"), " tidak menggunakan penjumlahan rank. Pada setiap sheet, model statistik (M0\u2013M4) diperiksa apakah menjadi minimum AICc, minimum CV_RMSE, atau minimum pada keduanya. Pemilihan utama didasarkan pada jumlah sheet ketika satu model menjadi terbaik pada ",
                                     tags$b("AICc dan CV_RMSE secara simultan"), ". Jika seri, kemenangan AICc lalu CV menjadi pemutus. Random Forest tidak punya AICc, jadi diperlakukan sebagai benchmark."),
                            section_title("Perbandingan AICc dan CV \u00b7 Sheet Comparison"),
                            sel_input("p3_cmp_sheet", "Pilih sheet untuk comparison", SHEETS),
                            div(class = "pick-grid",
                                div(tags$b("AICc \u2014 minimum per sheet di-highlight"), uiOutput("p3_aic_tbl")),
                                div(tags$b("CV_RMSE \u2014 minimum model statistik per sheet di-highlight"), uiOutput("p3_cv_tbl"))),
                            tags$b("Parameter yang dipilih"), uiOutput("p3_param_tbl"),
                            div(style = "height:.8rem"),
                            tabsetPanel(id = "p3_tabs", type = "pills",
                                        tabPanel("AICc", div(style = "height:.5rem"), div(class = "chart-card", plotlyOutput("p3_aic_plot", height = "430px")), uiOutput("p3_aic_cards")),
                                        tabPanel("CV_RMSE", div(style = "height:.5rem"), div(class = "chart-card", plotlyOutput("p3_cv_plot", height = "430px")), uiOutput("p3_cv_cards")),
                                        tabPanel("Pengaruh Pengacakan", div(style = "height:.5rem"), uiOutput("p3_shuffle_note"),
                                                 tags$b("AICc dan CV_RMSE pada setiap pengacakan"), uiOutput("p3_stab_tbl"),
                                                 tags$b("Rata-rata dan simpangan baku metrik pada lima pengacakan"), uiOutput("p3_summary_tbl"),
                                                 div(class = "chart-card", plotlyOutput("p3_rmse_plot", height = "400px")),
                                                 div(style = "height:.9rem"),
                                                 div(class = "chart-card", plotlyOutput("p3_bias_plot", height = "430px")),
                                                 div(class = "caption-line", "Bias = rata-rata (aktual \u2212 prediksi); positif berarti underprediction. Interval bootstrap 95% yang mencakup nol belum memberi bukti bias rata-rata pada subset uji tersebut, tetapi bukan bukti model bebas bias."))),
                            section_title("Model terbaik per sheet"),
                            div(style = "display:grid;grid-template-columns:1fr 1fr;gap:1rem;",
                                sel_input("p3_best_sheet", "Pilih sheet untuk grafik model terbaik", SHEETS),
                                sel_input("p3_best_feature", "Prediktor grafik", FEATURES)),
                            uiOutput("p3_best_widget")
  )
  
  page4 <- conditionalPanel("input.page == 'p4'",
                            hero("04 \u00b7 Diagnostik & Inferensi", paste0("Diagnostik model terpilih, inferensi, dan benchmark prediksi pada ", first_sheet, " (pengacakan pertama), serta pembahasan lintas lima pengacakan.")),
                            tabsetPanel(id = "p4_tabs", type = "pills",
                                        tabPanel("Diagnostik", div(style = "height:.5rem"), uiOutput("p4_diag_intro"),
                                                 div(class = "chart-card", plotlyOutput("p4_resid", height = "380px")),
                                                 div(style = "height:.9rem"), div(class = "chart-card", plotlyOutput("p4_qq", height = "360px")),
                                                 section_title("Uji asumsi residual"), uiOutput("p4_assump"),
                                                 note_box("Dengan n besar, uji formal hampir selalu menolak H0 meskipun penyimpangannya kecil, sehingga keputusan didasarkan pada plot. Penyimpangan normalitas dan heteroskedastisitas tidak mengganggu prediksi titik maupun CV, tetapi memengaruhi SE/p-value klasik; karena itu baseline memakai SE robust HC3."),
                                                 section_title("Cook's distance"), div(class = "chart-card", plotlyOutput("p4_cook", height = "360px")),
                                                 uiOutput("p4_cook_tbl"), tags$b("Sensitivitas: RMSE uji dengan dan tanpa observasi berpengaruh"), uiOutput("p4_sens"),
                                                 uiOutput("p4_gam_diag")),
                                        tabPanel("Inferensi", div(style = "height:.5rem"),
                                                 section_title("Baseline linear dengan SE robust (HC3)"), uiOutput("p4_hc3"),
                                                 section_title("Uji F model bersarang"), uiOutput("p4_anova"),
                                                 section_title("GAM: signifikansi dan bentuk fungsi smooth"), uiOutput("p4_gam_s"),
                                                 div(class = "chart-card", plotlyOutput("p4_gam_eff", height = "360px")),
                                                 div(class = "caption-line", "Pita = \u00b12 SE. edf \u2248 1 berarti hubungan praktis linear; edf besar berarti melengkung."),
                                                 section_title("Selisih akurasi data uji (bootstrap berpasangan)"), uiOutput("p4_paired"),
                                                 div(class = "chart-card", plotlyOutput("p4_paired_plot", height = "340px"))),
                                        tabPanel("Prediksi (Random Forest)", div(style = "height:.5rem"),
                                                 div(class = "pick-grid",
                                                     div(section_title("Permutation importance"), div(class = "chart-card", plotlyOutput("p4_imp", height = "300px")), uiOutput("p4_imp_tbl")),
                                                     div(section_title("Partial dependence AT: RF vs GAM"), div(class = "chart-card", plotlyOutput("p4_pdp", height = "300px")), uiOutput("p4_rf_perf"))),
                                                 note_box(tags$b("Yang tidak boleh disimpulkan dari benchmark:"), " (1) permutation importance bukan efek kausal dan bisa terdistorsi oleh korelasi AT\u2013V; (2) RMSE yang lebih kecil tidak berarti model \"benar\", hanya lebih akurat pada distribusi data ini; (3) RF tidak dapat mengekstrapolasi di luar rentang data latih; (4) RF tidak ikut perbandingan AICc.")),
                                        tabPanel("Pembahasan", div(style = "height:.5rem"), uiOutput("p4_discuss"),
                                                 section_title("Kesepakatan AICc dan CV"), uiOutput("p4_rank"),
                                                 div(class = "pick-grid",
                                                     div(section_title("Frekuensi model terpilih"), uiOutput("p4_pickfreq")),
                                                     div(section_title("Frekuensi mtry terpilih (CV RF)"), uiOutput("p4_mtryfreq"))),
                                                 section_title("Keterbatasan"),
                                                 note_box(tags$ol(
                                                   tags$li("Data hanya mencakup kondisi beban penuh pada satu pembangkit, sehingga model tidak berlaku untuk beban parsial atau pembangkit lain."),
                                                   tags$li("Tidak ada informasi waktu; jika observasi berurutan per jam saling berkorelasi, CV acak dapat sedikit terlalu optimis."),
                                                   tags$li("AICc hanya membandingkan model di dalam himpunan kandidat; model terbaik menurut AICc belum tentu model yang benar."),
                                                   tags$li("AICc GAM bergantung pada pendekatan edf; ketidakpastian smoothing parameter tidak sepenuhnya tercermin di k."),
                                                   tags$li("Residual tidak normal dan heteroskedastik, sehingga inferensi klasik pada polinomial perlu dibaca hati-hati."),
                                                   tags$li("Random Forest adalah benchmark prediksi, bukan model inferensi yang dibandingkan dengan AICc."))))
                            )
  )
  
  ui <- page_sidebar(
    title = NULL, fillable = FALSE,
    theme = bs_theme(version = 5, bg = "#f5f7fb", fg = "#152033", primary = "#5967f2",
                     base_font = font_collection("Inter", "Segoe UI", "system-ui", "sans-serif")),
    sidebar = sidebar(width = 285, open = "desktop",
                      div(class = "brand", "\u25c8 ANALYTICS LAB"),
                      div(class = "small-muted", "AICc \u2022 Cross-Validation \u2022 Regression"),
                      tags$hr(),
                      div(class = "nav-title", "NAVIGASI"),
                      div(class = "nav-radio", radioButtons("page", NULL, choices = NAV_CHOICES, selected = "p1")),
                      tags$hr(),
                      div(class = "small-muted", paste0("Data: ", basename(META$data_file))),
                      div(class = "small-muted", paste0("Hasil dibuat: ", META$created)),
                      div(class = "small-muted", "Dashboard hanya membaca hasil R.Rmd.")),
    tags$head(tags$style(HTML(APP_CSS)), tags$script(HTML(ASSISTANT_JS)), tags$title(APP_TITLE)),
    div(class = "small-muted", style = "margin-bottom:.3rem;",
        paste0("SOURCE \u00b7 R.Rmd \u00b7 DATA \u00b7 ", basename(META$data_file))),
    page1, page2, page3, page4,
    assistant_ui()
  )
}

# -----------------------------------------------------------------------------
# Server
# -----------------------------------------------------------------------------
server <- function(input, output, session) {
  if (is.null(PAYLOAD)) return(invisible(NULL))
  sheet_of <- function(sh) PAYLOAD$sheets[[sh]]
  active_sheet <- reactiveVal(SHEETS[1])
  observeEvent(input$p2_sheet, active_sheet(input$p2_sheet))
  
  # ============================ Halaman 1 ============================
  eda <- reactive(sheet_of(req(input$p1_sheet))$eda)
  output$p1_cards <- renderUI({
    e <- eda()
    card_row(metric_card("Observasi", fmt_int(e$n), "baris lengkap"),
             metric_card("Prediktor", length(FEATURES), paste(FEATURES, collapse = ", ")),
             metric_card("Missing", fmt_int(e$n_missing), "nilai sebelum dropna"),
             metric_card("Duplikat", fmt_int(e$n_dup), "baris duplikat"))
  })
  N_PREVIEW <- 10
  output$p1_data_caption <- renderUI({
    d <- eda()$data
    sprintf("Menampilkan %d dari %s record (%s). Gunakan tombol untuk mengunduh seluruh data sheet ini.",
            min(N_PREVIEW, nrow(d)), fmt_int(nrow(d)), req(input$p1_sheet))
  })
  output$p1_data_tbl <- renderUI({
    d <- eda()$data; d <- head(d, N_PREVIEW)
    html_table(cbind(No = seq_len(nrow(d)), d), digits = 2, col_digits = c(No = 0))
  })
  output$p1_download <- downloadHandler(
    filename = function() paste0("dataset_", req(input$p1_sheet), ".csv"),
    content = function(file) utils::write.csv(eda()$data, file, row.names = FALSE)
  )
  output$p1_desc <- renderUI({
    d <- eda()$desc; names(d)[names(d) == "Q1"] <- "25%"; names(d)[names(d) == "Q3"] <- "75%"
    html_table(d, digits = 4, col_digits = c(count = 0))
  })
  output$p1_hist <- renderPlotly({
    d <- eda()$data; vars <- names(d)
    cols <- c("#5967f2", "#11a7a0", "#e48620", "#7c5cd6", "#d6455d")
    plots <- lapply(seq_along(vars), function(i) {
      plot_ly(x = d[[vars[i]]], type = "histogram", nbinsx = 45, marker = list(color = cols[i], line = list(color = "#fff", width = .4)),
              opacity = .85, showlegend = FALSE, hovertemplate = "%{x}<br>n = %{y}<extra></extra>") %>%
        layout(xaxis = c(list(title = vars[i]), axis_style), yaxis = axis_style)
    })
    subplot(plots, nrows = 2, margin = 0.055, titleX = TRUE, shareY = FALSE) %>% pl_theme(height = 500)
  })
  output$p1_corr <- renderPlotly({
    cm <- eda()$corr; nm <- colnames(cm)
    ann <- do.call(c, lapply(seq_along(nm), function(i) lapply(seq_along(nm), function(j)
      list(x = nm[j], y = nm[i], text = sprintf("%.2f", cm[i, j]), showarrow = FALSE,
           font = list(color = if (abs(cm[i, j]) > .6) "#fff" else "#152033", size = 12)))))
    plot_ly(z = cm, x = nm, y = nm, type = "heatmap", zmin = -1, zmax = 1,
            colorscale = list(c(0, "#d6455d"), c(.5, "#f7f9fd"), c(1, "#5967f2")),
            hovertemplate = "%{y} \u00d7 %{x}: %{z:.3f}<extra></extra>") %>%
      layout(annotations = ann, yaxis = list(autorange = "reversed")) %>%
      pl_theme(height = 460, title = "Matriks korelasi")
  })
  output$p1_scatter <- renderPlotly({
    e <- eda(); s <- e$scatter
    plots <- lapply(seq_along(FEATURES), function(i) {
      f <- FEATURES[i]; ln <- e$lines[[f]]
      plot_ly() %>%
        add_trace(type = "scattergl", mode = "markers", x = s[[f]], y = s$PE, marker = list(size = 4, opacity = .30, color = "#5967f2"),
                  name = "Data (sampel)", showlegend = i == 1, hoverinfo = "skip") %>%
        add_trace(type = "scatter", mode = "lines", x = ln$x, y = ln$lm, line = list(color = "#7a879b", dash = "dash", width = 2),
                  name = "Linear", showlegend = i == 1) %>%
        add_trace(type = "scatter", mode = "lines", x = ln$x, y = ln$smooth, line = list(color = "#e48620", width = 3),
                  name = "Smooth (GAM)", showlegend = i == 1) %>%
        layout(xaxis = c(list(title = f), axis_style), yaxis = c(list(title = if (i == 1) "PE" else ""), axis_style))
    })
    subplot(plots, nrows = 1, margin = 0.035, titleX = TRUE, shareY = TRUE) %>%
      pl_theme(height = 380, title = "PE terhadap tiap prediktor (sampel 2.500 titik)")
  })
  output$p1_vif <- renderUI(html_table(eda()$vif, digits = 3))
  output$p1_outlier <- renderUI({ d <- eda()$outlier; names(d) <- gsub("_", " ", names(d)); html_table(d, digits = 4, col_digits = c(Outlier = 0)) })
  
  # ============================ Halaman 2 ============================
  sd2 <- reactive(sheet_of(req(input$p2_sheet)))
  output$p2_caption <- renderUI({
    sd <- sd2()
    tagList(div(style = "margin-top:.5rem", span(class = "badge-x", "mgcv GAM (REML)"), " ", span(class = "badge-x badge-green", "ranger Random Forest")),
            div(class = "caption-line", sprintf("Train = %s | Test = %s | CV = %d-fold | Seed = %d | Target = PE",
                                                fmt_int(sd$n_train), fmt_int(sd$n_test), META$k_folds, META$seed)))
  })
  feat2 <- reactive(req(input$p2_feature))
  
  # --- Polinomial & interaksi
  poly_items <- reactive({
    sd <- sd2(); tb <- sd$table
    lapply(POLY_MODELS, function(m) { r <- tb[tb$Model == m, ]
    list(label = m, k = r$k, aicc = r$AICc, cv = r$CV_RMSE, pred = sd$final[[m]]$pred, lines = sd$final[[m]]$lines) })
  })
  output$p2_poly_tbl <- renderUI({
    tb <- sd2()$table; d <- tb[tb$Model %in% POLY_MODELS, c("Model", "k", "AICc", "CV_RMSE", "CV_SE", "w_Akaike")]
    names(d)[names(d) == "w_Akaike"] <- "Bobot Akaike"
    html_table(d, col_digits = c(k = 0, AICc = 2, CV_RMSE = 4, CV_SE = 4, `Bobot Akaike` = 3), hi_aicc = "AICc", hi_cv = "CV_RMSE")
  })
  live_server("poly", poly_items, feat2, sd2, reactive(input$p2_sheet),
              plot_title = function(it) paste0(it$label, " \u00b7 data test"),
              cards_best = function(it, m) metric_grid(list(list("Model", short_model(it$label), "CV minimum"),
                                                            list("AICc", fmt_num(it$aicc, 2), "model terbaik"), list("CV RMSE", fmt_num(it$cv, 4), "model terbaik"),
                                                            list("Test RMSE", fmt_num(m[["rmse"]], 4), "seluruh test data"))),
              ptitle = "Model kandidat",
              tips = "<b>Tips:</b><br>\u2022 Geser slider model dari linear ke polinomial/interaksi.<br>\u2022 AICc menghukum jumlah parameter; CV menilai prediksi pada data yang tidak dipakai untuk fit.<br>\u2022 Garis hijau = model aktif; garis biru putus-putus = model terbaik CV.",
              short_fn = function(z) short_model(z$label),
              extra_fn = function(z) list("k (parameter)", fmt_num(z$k, 0)),
              cls_fn = function(z) if (grepl("Linear", z$label)) "Linear \u00b7 baseline" else if (grepl("interaksi", z$label)) "Derajat 2 + interaksi" else if (grepl("Polinomial-3", z$label)) "Kubik aditif" else "Kuadratik aditif",
              note_fn = function(z) sprintf("Model ini memiliki k = %s parameter (termasuk varians galat). AICc memberi penalti pada k yang besar, sedangkan CV menilai akurasi prediksi pada data yang tidak dipakai untuk fit.", fmt_num(z$k, 0)))
  
  # --- GAM (grid faktor penalti)
  gam_items <- reactive({
    sd <- sd2()
    lapply(sd$gam_grid, function(z) list(label = sprintf("sp \u00d7 10^%d", z$exponent), exponent = z$exponent, edf = z$edf, k = z$k,
                                         aicc = z$aicc, cv = z$cv, pred = z$pred, lines = z$lines))
  })
  output$p2_gam_tbl <- renderUI({
    g <- sd2()$gam_grid
    d <- data.frame(`log10(faktor sp)` = vapply(g, function(z) z$exponent, 0), edf = vapply(g, function(z) z$edf, 0),
                    k = vapply(g, function(z) z$k, 0), AICc = vapply(g, function(z) z$aicc, 0), CV_RMSE = vapply(g, function(z) z$cv, 0), check.names = FALSE)
    html_table(d, col_digits = c(`log10(faktor sp)` = 0, edf = 2, k = 2, AICc = 2, CV_RMSE = 4), hi_aicc = "AICc", hi_cv = "CV_RMSE")
  })
  live_server("gam", gam_items, feat2, sd2, reactive(input$p2_sheet),
              plot_title = function(it) sprintf("%s \u00b7 %s \u00b7 data test", GAM_NAME, it$label),
              cards_best = function(it, m) metric_grid(list(list("Faktor sp", paste0("10^", it$exponent), "CV minimum"),
                                                            list("AICc", fmt_num(it$aicc, 2), "faktor CV terpilih"), list("CV RMSE", fmt_num(it$cv, 4), "faktor CV terpilih"),
                                                            list("Test RMSE", fmt_num(m[["rmse"]], 4), "seluruh test data"))),
              ptitle = "log10(faktor sp)",
              tips = "<b>Tips:</b><br>\u2022 Faktor kecil \u2192 penalti lemah, kurva lentur (edf besar).<br>\u2022 Faktor besar \u2192 penalti kuat, kurva mendekati linear.<br>\u2022 Faktor 0 = smoothing parameter hasil REML.",
              short_fn = function(z) as.character(z$exponent),
              extra_fn = function(z) list("edf", fmt_num(z$edf, 2)),
              cls_fn = function(z) if (z$exponent < 0) "Penalti lemah \u00b7 kurva lentur" else if (z$exponent == 0) "Penalti REML \u00b7 pilihan data" else "Penalti kuat \u00b7 mendekati linear",
              note_fn = function(z) sprintf("edf total = %s. edf kecil berarti kurva mendekati linear; edf besar berarti kurva sangat lentur dan berisiko overfit.", fmt_num(z$edf, 2)))
  
  # --- Random Forest (grid mtry)
  rf_items <- reactive({
    sd <- sd2()
    lapply(sd$rf_grid, function(z) list(label = paste0("mtry = ", z$mtry), mtry = z$mtry, oob = z$oob, is_final = z$is_final,
                                        aicc = NA_real_, cv = z$cv, pred = z$pred, lines = z$lines))
  })
  output$p2_rf_tbl <- renderUI({
    g <- sd2()$rf_grid
    d <- data.frame(mtry = vapply(g, function(z) z$mtry, 0), `CV_RMSE (mtry tetap)` = vapply(g, function(z) z$cv, 0),
                    `OOB_RMSE` = vapply(g, function(z) z$oob, 0), `mtry akhir (OOB)` = vapply(g, function(z) z$is_final, logical(1)), check.names = FALSE)
    html_table(d, col_digits = c(mtry = 0, `CV_RMSE (mtry tetap)` = 4, OOB_RMSE = 4), hi_cv = "CV_RMSE (mtry tetap)")
  })
  live_server("rf", rf_items, feat2, sd2, reactive(input$p2_sheet),
              plot_title = function(it) sprintf("Random Forest \u00b7 %s \u00b7 data test", it$label),
              cards_best = function(it, m) metric_grid(list(list("mtry", it$mtry, "CV minimum"), list("OOB RMSE", fmt_num(it$oob, 4), "mtry CV terpilih"),
                                                            list("CV RMSE", fmt_num(it$cv, 4), "mtry CV terpilih"), list("Test RMSE", fmt_num(m[["rmse"]], 4), "seluruh test data"))),
              ptitle = "mtry",
              tips = "<b>Tips:</b><br>\u2022 mtry kecil \u2192 pohon lebih acak dan saling berbeda.<br>\u2022 mtry = jumlah prediktor \u2192 setara bagging.<br>\u2022 Random Forest tidak punya likelihood, jadi tidak ada AICc.",
              short_fn = function(z) as.character(z$mtry),
              extra_fn = function(z) list("OOB RMSE", fmt_num(z$oob, 4)),
              cls_fn = function(z) if (z$mtry == 1) "mtry minimum \u00b7 pohon paling acak" else if (z$mtry >= length(FEATURES)) "mtry maksimum \u00b7 setara bagging" else "mtry menengah",
              note_fn = function(z) paste0("OOB RMSE = ", fmt_num(z$oob, 4), ".", if (isTRUE(z$is_final)) " Ini adalah mtry akhir pada analisis utama (dipilih lewat OOB)." else ""))
  
  # --- Ringkasan test set
  output$p2_summary <- renderUI({
    sd <- sd2(); tb <- sd$table; y <- sd$y_test
    rows <- lapply(ALL_MODELS, function(m) { r <- tb[tb$Model == m, ]
    sel <- if (m == RF_NAME) paste0("mtry akhir = ", r$RF_mtry_final, " (OOB)") else if (m == GAM_NAME) "sp (REML)" else "OLS"
    data.frame(Model = m, Seleksi = sel, AICc = r$AICc, CV_RMSE = r$CV_RMSE, Test_RMSE = r$Test_RMSE, Test_R2 = r$Test_R2,
               Test_MAE = r$Test_MAE, Test_Bias = r$Test_Bias, stringsAsFactors = FALSE) })
    ev <- function(it) c(rmse = sqrt(mean((y - it$pred)^2)), r2 = 1 - sum((y - it$pred)^2) / sum((y - mean(y))^2),
                         mae = mean(abs(y - it$pred)), bias = mean(y - it$pred))
    g <- sd$gam_grid[[which.min(vapply(sd$gam_grid, function(z) z$cv, 0))]]; eg <- ev(g)
    r <- sd$rf_grid[[which.min(vapply(sd$rf_grid, function(z) z$cv, 0))]]; er <- ev(r)
    rows[[length(rows) + 1]] <- data.frame(Model = GAM_NAME, Seleksi = sprintf("sp \u00d7 10^%d (grid CV)", g$exponent), AICc = g$aicc, CV_RMSE = g$cv,
                                           Test_RMSE = eg[["rmse"]], Test_R2 = eg[["r2"]], Test_MAE = eg[["mae"]], Test_Bias = eg[["bias"]], stringsAsFactors = FALSE)
    rows[[length(rows) + 1]] <- data.frame(Model = RF_NAME, Seleksi = sprintf("mtry = %d (grid CV)", r$mtry), AICc = NA_real_, CV_RMSE = r$cv,
                                           Test_RMSE = er[["rmse"]], Test_R2 = er[["r2"]], Test_MAE = er[["mae"]], Test_Bias = er[["bias"]], stringsAsFactors = FALSE)
    d <- do.call(rbind, rows)
    html_table(d, col_digits = c(AICc = 2), hi_aicc = "AICc", hi_cv = "CV_RMSE", elig = !(d$Model == RF_NAME), bench = d$Model == RF_NAME)
  })
  
  # ============================ Halaman 3 ============================
  output$p3_cards <- renderUI({
    sel <- SCORECARD[SCORECARD$Selected, ][1, ]; ns <- length(SHEETS)
    rf_cv <- mean(STAB$CV_RMSE[STAB$Model == RF_NAME]); best_stat_cv <- min(tapply(STAB$CV_RMSE[STAB$Model %in% STAT_MODELS], STAB$Model[STAB$Model %in% STAT_MODELS], mean))
    card_row(metric_card("Model terpilih \u00b7 AICc & CV", sel$Model, "terbaik pada kedua kriteria secara simultan"),
             metric_card("AICc Best", sprintf("%d/%d", sel[["AICc Best (sheet)"]], ns), "jumlah sheet dengan AICc minimum"),
             metric_card("CV Best", sprintf("%d/%d", sel[["CV Best (sheet)"]], ns), "jumlah sheet dengan CV_RMSE minimum"),
             metric_card("AICc & CV Best", sprintf("%d/%d", sel[["AICc & CV Best (sheet)"]], ns), "minimum pada kedua kriteria"))
  })
  output$p3_score <- renderUI({
    sc <- SCORECARD; d <- sc[, setdiff(names(sc), "Selected")]
    html_table(d, digits = 1, col_digits = c(`AICc Best (sheet)` = 0, `CV Best (sheet)` = 0, `AICc & CV Best (sheet)` = 0), sel = sc$Selected)
  })
  wide_metric <- function(col, models) {
    d <- data.frame(Sheet = SHEETS, stringsAsFactors = FALSE)
    for (m in models) d[[short_model(m)]] <- vapply(SHEETS, function(sh) STAB[[col]][STAB$Sheet == sh & STAB$Model == m], 0)
    d
  }
  output$p3_aic_tbl <- renderUI({ d <- wide_metric("AICc", STAT_MODELS); html_table(d, digits = 2, row_min = names(d)[-1]) })
  output$p3_cv_tbl <- renderUI({
    d <- wide_metric("CV_RMSE", ALL_MODELS); stat_cols <- short_model(STAT_MODELS)
    cls_note <- html_table(d, digits = 4, row_min = stat_cols)
    cls_note
  })
  output$p3_param_tbl <- renderUI({
    pk <- SUMM$picks
    d <- data.frame(Sheet = pk$Sheet, `Pemenang AICc` = pk$AICc, `Pemenang CV` = pk$CV, `Pemenang 1-SE` = pk$OneSE,
                    `mtry RF akhir` = vapply(SHEETS, function(sh) STAB$RF_mtry_final[STAB$Sheet == sh & STAB$Model == RF_NAME], 0),
                    `Faktor sp GAM (grid CV)` = vapply(SHEETS, function(sh) { g <- sheet_of(sh)$gam_grid; g[[which.min(vapply(g, function(z) z$cv, 0))]]$exponent }, 0),
                    check.names = FALSE)
    html_table(d, col_digits = c(`mtry RF akhir` = 0, `Faktor sp GAM (grid CV)` = 0))
  })
  
  lolli <- function(vals, models, digits, title, bench_model = NULL) {
    vals <- as.numeric(unname(vals)); ok <- is.finite(vals); lab <- short_model(models); cols <- unname(MODEL_COL[models])
    stat_idx <- which(ok & !(models %in% bench_model)); best <- stat_idx[which.min(vals[stat_idx])]
    ymin <- min(vals[ok]); ymax <- max(vals[ok]); dy <- (ymax - ymin); if (dy == 0) dy <- 1
    p <- plot_ly()
    for (i in which(ok)) {
      p <- p %>% add_segments(x = lab[i], xend = lab[i], y = ymin - .16 * dy, yend = vals[i], line = list(color = cols[i], width = 7), showlegend = FALSE, hoverinfo = "skip") %>%
        add_markers(x = lab[i], y = vals[i], marker = list(size = 15, color = cols[i], line = list(color = if (i == best) "#152033" else "#fff", width = if (i == best) 3 else 2)),
                    text = models[i], hovertemplate = paste0("%{text}<br>", fmt_num(vals[i], digits), "<extra></extra>"), showlegend = FALSE) %>%
        add_annotations(x = lab[i], y = vals[i], text = fmt_num(vals[i], digits), showarrow = FALSE, yshift = 20, font = list(color = cols[i], size = 12))
    }
    p %>% add_annotations(x = lab[best], y = vals[best], text = "<b>MINIMUM</b>", showarrow = FALSE, yshift = 38, font = list(size = 10, color = "#152033")) %>%
      pl_theme(height = 430, title = title, xaxis = c(list(title = "", categoryorder = "array", categoryarray = lab[ok]), axis_style),
               yaxis = c(list(title = "", range = c(ymin - .16 * dy, ymax + .22 * dy)), axis_style))
  }
  cmp_sheet <- reactive(req(input$p3_cmp_sheet))
  output$p3_aic_plot <- renderPlotly({
    sh <- cmp_sheet(); v <- vapply(STAT_MODELS, function(m) STAB$AICc[STAB$Sheet == sh & STAB$Model == m], 0)
    lolli(v, STAT_MODELS, 2, paste0("AICc comparison \u00b7 ", sh))
  })
  output$p3_cv_plot <- renderPlotly({
    sh <- cmp_sheet(); v <- vapply(ALL_MODELS, function(m) STAB$CV_RMSE[STAB$Sheet == sh & STAB$Model == m], 0)
    lolli(v, ALL_MODELS, 4, paste0("CV_RMSE comparison \u00b7 ", sh, " (RF = benchmark)"), bench_model = RF_NAME)
  })
  output$p3_aic_cards <- renderUI({
    sh <- cmp_sheet(); v <- vapply(STAT_MODELS, function(m) STAB$AICc[STAB$Sheet == sh & STAB$Model == m], 0); i <- which.min(v)
    metric_grid(list(list("Minimum AICc", fmt_num(v[i], 2), paste("antar model statistik pada", sh)), list("Model minimum", short_model(STAT_MODELS[i]), STAT_MODELS[i]),
                     list("Sheet", sh, "sheet aktif"), list("Jumlah model", length(STAT_MODELS), "M0\u2013M4 (RF tanpa AICc)")))
  })
  output$p3_cv_cards <- renderUI({
    sh <- cmp_sheet(); v <- vapply(STAT_MODELS, function(m) STAB$CV_RMSE[STAB$Sheet == sh & STAB$Model == m], 0); i <- which.min(v)
    rf <- STAB$CV_RMSE[STAB$Sheet == sh & STAB$Model == RF_NAME]
    metric_grid(list(list("Minimum CV_RMSE", fmt_num(v[i], 4), paste("model statistik pada", sh)), list("Model minimum", short_model(STAT_MODELS[i]), STAT_MODELS[i]),
                     list("Random Forest", fmt_num(rf, 4), "benchmark prediksi"), list("Sheet", sh, "sheet aktif")))
  })
  output$p3_shuffle_note <- renderUI({
    same <- all(SUMM$verify_df[[3]])
    note_box(tags$b("Struktur sheet:"), if (same) " kelima sheet teridentifikasi sebagai permutasi baris dari himpunan observasi yang sama." else " kelima sheet tidak terverifikasi sebagai permutasi baris yang identik.",
             " Variasi AICc/CV muncul karena pembagian latih/uji dan fold CV berbeda pada tiap sheet. Lima sheet bukan lima sampel independen; simpangan baku di bawah mengukur sensitivitas terhadap pembagian data.")
  })
  output$p3_stab_tbl <- renderUI({
    d <- data.frame(Sheet = SHEETS, stringsAsFactors = FALSE)
    for (m in STAT_MODELS) d[[paste0(short_model(m), " AICc")]] <- vapply(SHEETS, function(sh) STAB$AICc[STAB$Sheet == sh & STAB$Model == m], 0)
    for (m in ALL_MODELS) d[[paste0(short_model(m), " CV")]] <- vapply(SHEETS, function(sh) STAB$CV_RMSE[STAB$Sheet == sh & STAB$Model == m], 0)
    html_table(d, digits = 4, col_digits = setNames(rep(2, length(STAT_MODELS)), paste0(short_model(STAT_MODELS), " AICc")))
  })
  output$p3_summary_tbl <- renderUI({
    s <- SUMM$stab_summary[, c("Model", "CV_RMSE_mean", "CV_RMSE_sd", "Test_RMSE_mean", "Test_RMSE_sd", "Test_MAE_mean", "Test_R2_mean", "Test_Bias_mean", "Test_Bias_sd", "CV_to_Test_gap_mean")]
    html_table(s, digits = 4, hi_cv = c("CV_RMSE_mean", "Test_RMSE_mean"), bench = s$Model == RF_NAME)
  })
  output$p3_rmse_plot <- renderPlotly({
    p <- plot_ly(); cols <- c("#5967f2", "#11a7a0", "#e48620", "#7c5cd6", "#d6455d")
    mods <- rev(ALL_MODELS)
    for (i in seq_along(SHEETS)) {
      t <- STAB[STAB$Sheet == SHEETS[i], ]; t <- t[match(mods, t$Model), ]
      p <- p %>% add_trace(type = "scatter", mode = "markers", x = t$Test_RMSE, y = short_model(t$Model), name = SHEETS[i],
                           marker = list(size = 10, color = cols[(i - 1) %% 5 + 1], opacity = .85, line = list(color = "#fff", width = 1)))
    }
    p %>% pl_theme(height = 400, title = "Test RMSE menurut model dan pengacakan", xaxis = c(list(title = "Test RMSE (MW)"), axis_style),
                   yaxis = c(list(title = "", categoryorder = "array", categoryarray = short_model(mods)), axis_style))
  })
  output$p3_bias_plot <- renderPlotly({
    p <- plot_ly(); cols <- c("#5967f2", "#11a7a0", "#e48620", "#7c5cd6", "#d6455d")
    mods <- rev(ALL_MODELS); pos <- seq_along(mods); off <- seq(-.25, .25, length.out = length(SHEETS))
    for (i in seq_along(SHEETS)) {
      t <- STAB[STAB$Sheet == SHEETS[i], ]; t <- t[match(mods, t$Model), ]
      p <- p %>% add_trace(type = "scatter", mode = "markers", x = t$Test_Bias, y = pos + off[i], name = SHEETS[i],
                           marker = list(size = 8, color = cols[(i - 1) %% 5 + 1]),
                           error_x = list(type = "data", symmetric = FALSE, array = t$Test_Bias_hi - t$Test_Bias, arrayminus = t$Test_Bias - t$Test_Bias_lo,
                                          color = cols[(i - 1) %% 5 + 1], thickness = 1.4, width = 3),
                           text = short_model(t$Model), hovertemplate = "%{text}<br>Bias = %{x:.3f}<extra></extra>")
    }
    p %>% layout(shapes = list(list(type = "line", x0 = 0, x1 = 0, y0 = .4, y1 = length(mods) + .6, line = list(color = "#7a879b", dash = "dash")))) %>%
      pl_theme(height = 430, title = "Bias prediksi pada data uji (aktual \u2212 prediksi), interval bootstrap 95%",
               xaxis = c(list(title = "Mean error / bias (MW)"), axis_style),
               yaxis = c(list(title = "", tickvals = pos, ticktext = short_model(mods), range = c(.4, length(mods) + .6)), axis_style))
  })
  
  # --- Model terbaik per sheet (slider ala lab interaktif, dihitung di browser)
  best_sd <- reactive(sheet_of(req(input$p3_best_sheet)))
  best_ctx <- reactive({
    sh <- req(input$p3_best_sheet); bm <- best_model_of(sh); sd <- best_sd(); tb <- sd$table; r <- tb[tb$Model == bm$model, ]
    list(sh = sh, bm = bm, sd = sd, row = r, fin = sd$final[[bm$model]])
  })
  output$p3_best_widget <- renderUI({
    ctx <- best_ctx(); sd <- ctx$sd; f <- req(input$p3_best_feature); r <- ctx$row
    it <- list(label = ctx$bm$model, short = short_model(ctx$bm$model), aicc = r$AICc, cv = r$CV_RMSE,
               extra = list("Status seleksi", if (ctx$bm$agree) "AICc & CV terbaik" else "tidak keduanya"),
               cls = if (ctx$bm$agree) "AICc & CV sepakat" else "AICc dan CV tidak sepakat",
               note = if (ctx$bm$agree) paste0("AICc dan CV_RMSE sama-sama memilih model ini pada ", ctx$sh, ".")
               else paste0("Pada ", ctx$sh, " AICc memilih ", ctx$bm$aicc_pick, ", sedangkan CV_RMSE memilih model ini; tampilan mengikuti minimum CV_RMSE."),
               pred = ctx$fin$pred, line = ctx$fin$lines[[f]])
    live_widget(uid = paste0("best_", gsub("[^A-Za-z0-9]", "", ctx$sh)), items = list(it), X = sd$X_test[[f]], Y = sd$y_test,
                grid = sd$grids[[f]], feature = f, ptitle = NULL,
                tips = "<b>Tips:</b><br>\u2022 Geser jumlah data test untuk melihat kestabilan Test RMSE dan R\u00b2.<br>\u2022 Sheet dan prediktor dipilih lewat dropdown di atas grafik.")
  })
  
  # ============================ Halaman 4 ============================
  D <- DETAIL
  two_panel <- function(f, ...) subplot(lapply(c("base", "sel"), f), nrows = 1, margin = 0.05, titleX = TRUE, shareY = FALSE, ...)
  output$p4_diag_intro <- renderUI(note_box("Diagnostik dilakukan pada model statistik terpilih menurut CV (", tags$b(D$ref_model), ") dan pada baseline linear sebagai pembanding, memakai data latih ", first_sheet, "."))
  output$p4_resid <- renderPlotly({
    two_panel(function(k) { z <- D$diag[[k]]
    plot_ly() %>% add_trace(type = "scattergl", mode = "markers", x = z$sample$fitted, y = z$sample$resid, marker = list(size = 4, opacity = .18, color = "#25334a"), hoverinfo = "skip", showlegend = FALSE) %>%
      add_trace(type = "scatter", mode = "lines", x = z$smooth$x, y = z$smooth$y, line = list(color = "#e48620", width = 3), showlegend = FALSE) %>%
      layout(shapes = list(list(type = "line", xref = "paper", x0 = 0, x1 = 1, y0 = 0, y1 = 0, line = list(color = "#d6455d", width = 1.5))),
             xaxis = c(list(title = paste("Fitted PE \u00b7", z$label)), axis_style), yaxis = c(list(title = if (k == "base") "Residual" else ""), axis_style)) }) %>%
      pl_theme(height = 380, title = "Residual vs fitted (garis oranye = smooth)")
  })
  output$p4_qq <- renderPlotly({
    two_panel(function(k) { z <- D$diag[[k]]; xr <- range(z$qq$x)
    plot_ly() %>% add_trace(type = "scattergl", mode = "markers", x = z$qq$x, y = z$qq$y, marker = list(size = 5, opacity = .5, color = "#5967f2"), showlegend = FALSE, hoverinfo = "skip") %>%
      add_trace(type = "scatter", mode = "lines", x = xr, y = z$qq_line[["intercept"]] + z$qq_line[["slope"]] * xr, line = list(color = "#d6455d"), showlegend = FALSE) %>%
      layout(xaxis = c(list(title = paste("Kuantil teoretis \u00b7", z$label)), axis_style), yaxis = c(list(title = if (k == "base") "Kuantil residual" else ""), axis_style)) }) %>%
      pl_theme(height = 360, title = "QQ-plot residual")
  })
  output$p4_assump <- renderUI({ d <- D$assump; html_table(d, digits = 3, col_digits = c(BP = 2)) })
  output$p4_cook <- renderPlotly({
    two_panel(function(k) { z <- D$diag[[k]]; idx <- seq_along(z$cook)
    plot_ly() %>% add_trace(type = "scattergl", mode = "markers", x = idx, y = z$cook, marker = list(size = 3, color = "#5967f2", opacity = .55), showlegend = FALSE, hoverinfo = "y") %>%
      layout(shapes = list(list(type = "line", xref = "paper", x0 = 0, x1 = 1, y0 = D$thr_cook, y1 = D$thr_cook, line = list(color = "#d6455d", dash = "dash"))),
             xaxis = c(list(title = paste("Observasi \u00b7", z$label)), axis_style), yaxis = c(list(title = if (k == "base") "Cook's D" else ""), axis_style)) }) %>%
      pl_theme(height = 360, title = "Cook's distance (garis merah = 4/n)")
  })
  output$p4_cook_tbl <- renderUI(html_table(D$cook_sum, digits = 4, col_digits = c(n_cook_gt_4n = 0)))
  output$p4_sens <- renderUI(html_table(D$sens_infl, digits = 4))
  output$p4_gam_diag <- renderUI({
    if (is.null(D$kcheck)) return(NULL)
    tagList(section_title("Pemeriksaan dimensi basis GAM (k-index < 1 dan p kecil perlu ditinjau)"), html_table(D$kcheck, digits = 4),
            section_title("Concurvity GAM (nilai tinggi perlu diwaspadai)"), html_table(D$concurvity, digits = 3))
  })
  output$p4_hc3 <- renderUI(html_table(D$hc3, digits = 4))
  output$p4_anova <- renderUI(tagList(tags$b("M0 vs M1 vs M2"), html_table(D$anova_012, digits = 4), tags$b("M1 vs M3"), html_table(D$anova_13, digits = 4)))
  output$p4_gam_s <- renderUI(html_table(D$gam_smooth, digits = 4))
  output$p4_gam_eff <- renderPlotly({
    e <- D$gam_effects; if (is.null(e)) return(NULL)
    plots <- lapply(seq_along(FEATURES), function(i) { z <- e[e$Variabel == FEATURES[i], ]
    plot_ly() %>% add_ribbons(x = z$x, ymin = z$fit - 2 * z$se, ymax = z$fit + 2 * z$se, fillcolor = "rgba(89,103,242,.18)", line = list(width = 0), showlegend = FALSE, hoverinfo = "skip") %>%
      add_lines(x = z$x, y = z$fit, line = list(color = "#5967f2", width = 3), showlegend = FALSE) %>%
      layout(xaxis = c(list(title = FEATURES[i]), axis_style), yaxis = c(list(title = if (i == 1) "Efek smooth" else ""), axis_style)) })
    subplot(plots, nrows = 1, margin = 0.04, titleX = TRUE, shareY = FALSE) %>% pl_theme(height = 360, title = "Efek smooth GAM tiap prediktor")
  })
  output$p4_paired <- renderUI({
    d <- D$paired_diff; d <- d[, c("Model", "Pembanding", "Selisih_RMSE", "CI_lo", "CI_hi", "Signifikan")]
    html_table(d, digits = 3)
  })
  output$p4_paired_plot <- renderPlotly({
    d <- D$paired_diff
    plot_ly(d, x = ~Selisih_RMSE, y = ~short_model(Model), type = "scatter", mode = "markers", marker = list(size = 11, color = "#5967f2"),
            error_x = list(type = "data", symmetric = FALSE, array = ~CI_hi - Selisih_RMSE, arrayminus = ~Selisih_RMSE - CI_lo, color = "#5967f2"),
            hovertemplate = "%{y}<br>Selisih = %{x:.3f}<extra></extra>") %>%
      layout(shapes = list(list(type = "line", x0 = 0, x1 = 0, yref = "paper", y0 = 0, y1 = 1, line = list(color = "#7a879b", dash = "dash")))) %>%
      pl_theme(height = 340, title = paste("Selisih RMSE uji terhadap", D$ref_model, "(CI bootstrap 95%)"), xaxis = c(list(title = "Selisih RMSE (MW)"), axis_style), yaxis = c(list(title = ""), axis_style))
  })
  output$p4_imp <- renderPlotly({
    d <- D$rf_importance[order(D$rf_importance$Permutation_importance), ]
    plot_ly(d, x = ~Permutation_importance, y = ~factor(Variabel, levels = Variabel), type = "bar", orientation = "h", marker = list(color = "#0072B2")) %>%
      pl_theme(height = 300, xaxis = c(list(title = "Permutation importance"), axis_style), yaxis = c(list(title = ""), axis_style))
  })
  output$p4_imp_tbl <- renderUI(html_table(D$rf_importance, digits = 2))
  output$p4_pdp <- renderPlotly({
    d <- D$pdp; plot_ly() %>%
      add_lines(data = d[d$Model == "RF", ], x = ~AT, y = ~PE, name = "Random Forest", line = list(color = "#0072B2", width = 3)) %>%
      add_lines(data = d[d$Model == "GAM", ], x = ~AT, y = ~PE, name = "GAM", line = list(color = "#D55E00", width = 3)) %>%
      pl_theme(height = 300, xaxis = c(list(title = "AT"), axis_style), yaxis = c(list(title = "Rata-rata prediksi PE (MW)"), axis_style))
  })
  output$p4_rf_perf <- renderUI(tagList(div(class = "section-title", "Kinerja RF (pengacakan pertama)"), html_table(D$rf_perf, digits = 3, col_digits = c(RF_mtry_final = 0))))
  output$p4_discuss <- renderUI({
    S <- SUMM; cvm <- S$cv_mean; gam_cv <- cvm[[GAM_NAME]]; rf_cv <- cvm[[RF_NAME]]; m0_cv <- cvm[[POLY_MODELS[1]]]
    best_poly <- names(which.min(cvm[POLY_MODELS]))
    tagList(
      section_title("Pembahasan"),
      note_box(tags$b("Model statistik terbaik."), sprintf(" Pada %d dari %d pengacakan, model terpilih oleh AICc sama dengan model terpilih oleh CV; pemenang CV: %s. Rata-rata CV_RMSE %s = %s MW, polinomial/interaksi terbaik (%s) = %s MW, dan baseline linear (M0) = %s MW.",
                                                           S$n_agree, S$n_sheet, S$winner_cv, GAM_NAME, fmt_num(gam_cv, 3), best_poly, fmt_num(cvm[[best_poly]], 3), fmt_num(m0_cv, 3))),
      note_box(tags$b("Peran polinomial dan interaksi."), sprintf(" Uji F bersarang M1 vs M3 memberi F = %s, sehingga interaksi menurunkan RSS pada data latih. Namun M2 (aditif derajat 3) mengungguli M3 pada AICc di %d dari %d pengacakan, pada CV_RMSE di %d dari %d, dan pada RMSE data uji di %d dari %d.",
                                                                  fmt_num(S$F_M1_M3, 2), S$m2_lebih_aicc, S$n_sheet, S$m2_lebih_cv, S$n_sheet, S$m2_lebih_test, S$n_sheet)),
      note_box(tags$b("Random Forest sebagai benchmark."), sprintf(" Rata-rata CV_RMSE Random Forest = %s MW, %s %s (%s MW). %s",
                                                                   fmt_num(rf_cv, 3), if (rf_cv < gam_cv) "lebih rendah daripada" else "tidak lebih rendah daripada", GAM_NAME, fmt_num(gam_cv, 3),
                                                                   if (rf_cv < gam_cv) "Selisih ini menandakan ada struktur (misalnya interaksi tingkat tinggi) yang belum sepenuhnya ditangkap kandidat statistik. Namun RF tidak memberi koefisien, CI, atau uji hipotesis, sehingga tidak menggantikan model statistik untuk tujuan inferensi." else "RF tidak memberi koefisien, CI, atau uji hipotesis sehingga hanya berfungsi sebagai pembanding prediksi.")))
  })
  output$p4_rank <- renderUI({ d <- SUMM$rank_agreement; html_table(d, digits = 3) })
  output$p4_pickfreq <- renderUI(html_table(SUMM$pick_frequency, digits = 0))
  output$p4_mtryfreq <- renderUI(html_table(SUMM$rf_tuning_frequency, digits = 0))
  
  # ====================== Analysis Assistant ======================
  output$assistant_out <- renderUI({
    q <- req(input$assistant_q)
    tagList(div(class = "assistant-question", q),
            div(class = "assistant-answer", HTML(md_inline(assistant_answer(q, active_sheet())))))
  })
}

shinyApp(ui, server)