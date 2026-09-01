dynamic_base_year <- function(path = NULL) {
  value <- NULL

  if (is.null(path)) {
    value <- read_base_year_from_current_document()
    if (is.null(value)) {
      value <- read_base_year_from_project()
    }
  } else {
    value <- read_base_year_from_file(path)
  }

  if (is.null(value)) {
    stop("`base-year` est requis dans le front matter du document ou dans `_quarto.yml`.", call. = FALSE)
  }

  validate_integer(value, "`base-year`")
}

dynamic_year <- function(offset = 0, base_year = dynamic_base_year()) {
  validate_integer(base_year, "`base_year`") + validate_integer(offset, "`offset`")
}

dynamic_date <- function(x, offset = 0, invalid = c("error", "previous-month-end", "next-month-start"),
                         base_year = dynamic_base_year()) {
  invalid <- match.arg(invalid)
  target_year <- dynamic_year(offset = offset, base_year = base_year)

  if (inherits(x, "Date")) {
    value <- vapply(x, dynamic_date_one, character(1), target_year, invalid, "Date")
    return(as.Date(unname(value)))
  }

  if (is.numeric(x)) {
    year <- rep.int(target_year, length(x))
    year[is.na(x)] <- NA_integer_
    return(year)
  }

  if (is.character(x)) {
    value <- vapply(x, dynamic_date_one, character(1), target_year, invalid, "character")
    return(unname(value))
  }

  stop("`x` doit etre un objet Date, une chaine `YYYY-MM-DD`, une chaine `YYYY` ou une annee numerique.", call. = FALSE)
}

dynamic_date_one <- function(x, target_year, invalid, output_type) {
  if (is.na(x)) {
    return(NA_character_)
  }

  text <- if (output_type == "Date") format(x, "%Y-%m-%d") else x

  if (grepl("^(YYYY|[0-9]{4})$", text)) {
    return(sprintf("%04d", target_year))
  }

  parts <- regexec("^(YYYY|[0-9]{4})-([0-9]{2})-([0-9]{2})$", text)
  match <- regmatches(text, parts)[[1]]
  if (length(match) == 0) {
    stop("`x` doit utiliser le format `YYYY-MM-DD`, `yyyy-mm-dd` ou `yyyy`.", call. = FALSE)
  }

  month <- as.integer(match[[3]])
  day <- as.integer(match[[4]])
  build_dynamic_date(target_year, month, day, invalid)
}

build_dynamic_date <- function(year, month, day, invalid) {
  if (month < 1 || month > 12) {
    stop("La date dynamique contient un mois invalide.", call. = FALSE)
  }

  max_day <- days_in_month(year, month)
  if (day >= 1 && day <= max_day) {
    return(sprintf("%04d-%02d-%02d", year, month, day))
  }

  if (day < 1) {
    stop("La date dynamique contient un jour invalide.", call. = FALSE)
  }

  if (invalid == "previous-month-end") {
    return(sprintf("%04d-%02d-%02d", year, month, max_day))
  }

  if (invalid == "next-month-start") {
    if (month == 12) {
      return(sprintf("%04d-01-01", year + 1))
    }
    return(sprintf("%04d-%02d-01", year, month + 1))
  }

  stop(
    sprintf(
      "La date `%04d-%02d-%02d` est invalide. Utilisez invalid = \"previous-month-end\" ou invalid = \"next-month-start\" pour la corriger automatiquement.",
      year, month, day
    ),
    call. = FALSE
  )
}

days_in_month <- function(year, month) {
  if (month == 2) {
    return(if (is_leap_year(year)) 29L else 28L)
  }
  if (month %in% c(4L, 6L, 9L, 11L)) {
    return(30L)
  }
  31L
}

is_leap_year <- function(year) {
  year %% 4 == 0 && (year %% 100 != 0 || year %% 400 == 0)
}

validate_integer <- function(value, name) {
  number <- suppressWarnings(as.numeric(value))
  if (length(number) != 1 || is.na(number) || number != floor(number)) {
    stop(name, " doit etre un entier.", call. = FALSE)
  }
  as.integer(number)
}

read_base_year_from_current_document <- function() {
  candidates <- character()

  if (requireNamespace("knitr", quietly = TRUE)) {
    input <- knitr::current_input()
    if (!is.null(input) && nzchar(input)) {
      candidates <- c(candidates, sub("\\.rmarkdown$", ".qmd", input))
    }
  }

  candidates <- c(candidates, "index.qmd")
  candidates <- unique(file.path(getwd(), candidates))
  candidates <- candidates[file.exists(candidates)]

  for (candidate in candidates) {
    value <- read_base_year_from_file(candidate)
    if (!is.null(value)) {
      return(value)
    }
  }

  NULL
}

read_base_year_from_project <- function() {
  starts <- c(Sys.getenv("QUARTO_PROJECT_DIR", unset = ""), getwd())
  starts <- unique(normalizePath(starts[nzchar(starts)], mustWork = FALSE))

  for (start in starts) {
    current <- start
    repeat {
      candidate <- file.path(current, "_quarto.yml")
      value <- read_base_year_from_file(candidate)
      if (!is.null(value)) {
        return(value)
      }

      parent <- dirname(current)
      if (identical(parent, current)) {
        break
      }
      current <- parent
    }
  }

  NULL
}

read_base_year_from_file <- function(path) {
  if (is.null(path) || !file.exists(path)) {
    return(NULL)
  }

  lines <- readLines(path, warn = FALSE)
  if (length(lines) == 0) {
    return(NULL)
  }

  if (identical(trimws(lines[[1]]), "---")) {
    end <- which(trimws(lines[-1]) == "---")[1]
    if (!is.na(end)) {
      lines <- lines[seq_len(end + 1)]
    }
  }

  match <- regmatches(lines, regexec("^\\s*base-year\\s*:\\s*['\"]?([+-]?[0-9]+)['\"]?\\s*$", lines))
  values <- vapply(match, length, integer(1))
  if (!any(values > 1)) {
    return(NULL)
  }

  match[[which(values > 1)[1]]][[2]]
}
