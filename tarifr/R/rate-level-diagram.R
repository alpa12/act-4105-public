#' Add Months to a Date
#'
#' Advances a date by a fixed number of months.
#'
#' @param date A value coercible to `Date`.
#' @param months Number of months to add.
#'
#' @return A `Date`.
add_months <- function(date, months) {
  date <- as.Date(date)
  seq.Date(date, by = paste(months, "months"), length.out = 2)[2]
}

normalize_date <- function(date, arg_name) {
  value <- as.Date(date)

  if (is.na(value)) {
    stop(sprintf("`%s` must be a valid date.", arg_name), call. = FALSE)
  }

  value
}

date_num <- function(date) {
  as.numeric(as.Date(date))
}

default_column <- function(value, n) {
  rep(value, length.out = n)
}

draw_vertical_ticks <- function(x, start_y, end_y, lwd = 0.8) {
  graphics::segments(x0 = x, y0 = start_y, x1 = x, y1 = end_y, lwd = lwd)
}

validate_positive_months <- function(value, arg_name, allow_null = FALSE) {
  if (allow_null && is.null(value)) {
    return(invisible(NULL))
  }

  if (!is.numeric(value) || length(value) != 1 || is.na(value) || value <= 0) {
    stop(sprintf("`%s` must be a positive number.", arg_name), call. = FALSE)
  }

  invisible(NULL)
}

rate_level_style <- function() {
  list(
    fill_start = 0.96,
    fill_end = 0.75,
    border_col = "black",
    border_lwd = 1,
    period_boundary_col = grDevices::adjustcolor("black", alpha.f = 0.22),
    period_boundary_lwd = 0.7,
    major_grid_col = grDevices::adjustcolor("black", alpha.f = 0.10),
    major_grid_lty = 2,
    major_grid_lwd = 1,
    minor_grid_col = grDevices::adjustcolor("black", alpha.f = 0.12),
    minor_grid_lwd = 0.7,
    change_col = "black",
    change_lty = 2,
    change_lwd = 1.0,
    highlight_col = "gray25",
    highlight_lty = "8424",
    highlight_lwd = 2.8,
    zone_cex = 1.5,
    period_cex = 0.9,
    date_cex = 0.7,
    change_cex = 0.7,
    top_tick_length = 3,
    bottom_tick_length = 4,
    top_label_y = 106,
    change_date_y = -8,
    change_label_y = -18,
    date_label_y = -8,
    policy_line_col = "black",
    policy_line_lwd = 1,
    policy_label_cex = 1.0,
    point_cex = 1.6,
    reference_line_col = "black",
    reference_line_lwd = 2.2,
    reference_label_cex = 0.9
  )
}

experience_prefix <- function(experience_period) {
  year_method_prefix(experience_period)
}

experience_geometry <- function(experience_period) {
  if (experience_period == "policy") "parallelogram" else "rectangle"
}

build_periods <- function(start_date, end_date, period_months) {
  period_starts <- seq.Date(start_date, end_date, by = paste(period_months, "months"))

  if (length(period_starts) < 2 || tail(period_starts, 1) != end_date) {
    period_starts <- c(period_starts[period_starts < end_date], end_date)
  }

  if (length(period_starts) < 2) {
    stop("`start_date` must be earlier than `end_date` by at least one period.", call. = FALSE)
  }

  data.frame(
    start = period_starts[-length(period_starts)],
    end = period_starts[-1]
  )
}

period_polygon <- function(period_start, period_end, geometry, policy_term_months) {
  if (geometry == "rectangle") {
    return(list(
      x = date_num(c(period_start, period_end, period_end, period_start)),
      y = c(0, 0, 100, 100)
    ))
  }

  list(
    x = date_num(c(
      period_start,
      period_end,
      add_months(period_end, policy_term_months),
      add_months(period_start, policy_term_months)
    )),
    y = c(0, 0, 100, 100)
  )
}

draw_period_polygon <- function(period_start, period_end, geometry, policy_term_months, col, border, lwd, lty = 1) {
  poly <- period_polygon(period_start, period_end, geometry, policy_term_months)
  graphics::polygon(poly$x, poly$y, col = col, border = border, lwd = lwd, lty = lty)
}

draw_analyzed_outline <- function(period_start, period_end, geometry, policy_term_months, style) {
  poly <- period_polygon(period_start, period_end, geometry, policy_term_months)
  x <- c(poly$x, poly$x[1])
  y <- c(poly$y, poly$y[1])

  inset <- 0.7
  y <- pmin(pmax(y, inset), 100 - inset)

  graphics::segments(
    x[-length(x)],
    y[-length(y)],
    x[-1],
    y[-1],
    col = style$highlight_col,
    lwd = style$highlight_lwd,
    lty = style$highlight_lty
  )
}

draw_period_ticks <- function(x, bottom_tick_length, top_tick_length) {
  graphics::segments(x, 0, x, -bottom_tick_length)
  graphics::segments(x, 100, x, 100 + top_tick_length)
}

draw_minor_grid <- function(start_date, view_start, view_end, minor_grid_months, geometry, policy_term_months, col, lwd) {
  if (is.null(minor_grid_months)) {
    return(invisible(NULL))
  }

  grid_starts <- seq.Date(start_date, view_end, by = paste(minor_grid_months, "months"))
  grid_starts <- grid_starts[grid_starts >= view_start & grid_starts <= view_end]

  if (geometry == "rectangle") {
    graphics::segments(date_num(grid_starts), 0, date_num(grid_starts), 100, col = col, lwd = lwd)
    return(invisible(NULL))
  }

  for (grid_start in grid_starts) {
    line_end <- add_months(grid_start, policy_term_months)
    xa <- max(date_num(grid_start), date_num(view_start))
    xb <- min(date_num(line_end), date_num(view_end))

    if (xa >= xb) {
      next
    }

    width <- date_num(line_end) - date_num(grid_start)
    ya <- 100 * (xa - date_num(grid_start)) / width
    yb <- 100 * (xb - date_num(grid_start)) / width

    graphics::segments(xa, ya, xb, yb, col = col, lwd = lwd)
  }

  invisible(NULL)
}

period_label_x <- function(period_start, period_end, geometry, policy_term_months) {
  if (geometry == "rectangle") {
    return(mean(date_num(c(period_start, period_end))))
  }

  mean(date_num(c(add_months(period_start, policy_term_months), add_months(period_end, policy_term_months))))
}

format_period_label <- function(period_start, period_months, prefix) {
  if (period_months == 12) {
    return(paste(prefix, format(period_start, "%Y")))
  }

  if (period_months == 3) {
    quarter <- ((as.integer(format(period_start, "%m")) - 1) %/% 3) + 1
    return(paste(prefix, paste0(format(period_start, "%Y"), " Q", quarter)))
  }

  paste(prefix, format(period_start, "%Y-%m"))
}

normalize_changes <- function(changes, style) {
  if (is.null(changes)) {
    return(NULL)
  }

  if (!"date" %in% names(changes)) {
    stop("`changes` must contain a `date` column.", call. = FALSE)
  }

  changes$date <- as.Date(changes$date)

  if (anyNA(changes$date)) {
    stop("All `changes$date` values must be valid dates.", call. = FALSE)
  }

  if (!"type" %in% names(changes)) {
    changes$type <- default_column("diagonal", nrow(changes))
  }

  valid_types <- c("diagonal", "vertical")
  if (!all(changes$type %in% valid_types)) {
    stop("`changes$type` must contain only 'diagonal' or 'vertical'.", call. = FALSE)
  }

  if (!"label" %in% names(changes)) {
    changes$label <- default_column("", nrow(changes))
  }

  if (!"date_y" %in% names(changes)) {
    changes$date_y <- default_column(style$change_date_y, nrow(changes))
  }

  if (!"label_y" %in% names(changes)) {
    changes$label_y <- default_column(style$change_label_y, nrow(changes))
  }

  changes
}

normalize_zone_labels <- function(zone_labels, default_cex) {
  if (is.null(zone_labels)) {
    return(NULL)
  }

  if ("date" %in% names(zone_labels)) {
    zone_labels$x <- date_num(zone_labels$date)
  } else if (!"x" %in% names(zone_labels)) {
    stop("`zone_labels` must contain either a `date` column or an `x` column.", call. = FALSE)
  }

  if (!"label" %in% names(zone_labels)) {
    stop("`zone_labels` must contain a `label` column.", call. = FALSE)
  }

  if (!"y" %in% names(zone_labels)) {
    zone_labels$y <- default_column(50, nrow(zone_labels))
  }

  if (!"cex" %in% names(zone_labels)) {
    zone_labels$cex <- default_column(default_cex, nrow(zone_labels))
  }

  zone_labels
}

normalize_policies <- function(policies, policy_term_months, default_cex) {
  if (is.null(policies)) {
    return(NULL)
  }

  if (!"start" %in% names(policies)) {
    stop("`policies` must contain a `start` column.", call. = FALSE)
  }

  policies$start <- as.Date(policies$start)
  if (anyNA(policies$start)) {
    stop("All `policies$start` values must be valid dates.", call. = FALSE)
  }

  if ("end" %in% names(policies)) {
    policies$end <- as.Date(policies$end)
    if (anyNA(policies$end)) {
      stop("All `policies$end` values must be valid dates.", call. = FALSE)
    }
  } else {
    policies$end <- if (nrow(policies)) {
      do.call(c, lapply(policies$start, add_months, months = policy_term_months))
    } else {
      as.Date(character())
    }
  }

  if (any(policies$end <= policies$start)) {
    stop("All `policies$end` values must be later than `policies$start`.", call. = FALSE)
  }

  if (!"label" %in% names(policies)) {
    policies$label <- default_column("", nrow(policies))
  }

  if (!"label_y" %in% names(policies)) {
    policies$label_y <- default_column(64, nrow(policies))
  }

  if (!"label_cex" %in% names(policies)) {
    policies$label_cex <- default_column(default_cex, nrow(policies))
  }

  policies
}

normalize_points <- function(points, default_cex) {
  if (is.null(points)) {
    return(NULL)
  }

  if (!"date" %in% names(points)) {
    stop("`points` must contain a `date` column.", call. = FALSE)
  }

  points$date <- as.Date(points$date)
  if (anyNA(points$date)) {
    stop("All `points$date` values must be valid dates.", call. = FALSE)
  }

  if (!"y" %in% names(points)) {
    points$y <- default_column(0, nrow(points))
  }

  if (!"pch" %in% names(points)) {
    points$pch <- default_column(19, nrow(points))
  }

  if (!"cex" %in% names(points)) {
    points$cex <- default_column(default_cex, nrow(points))
  }

  points
}

normalize_reference_lines <- function(reference_lines, style) {
  if (is.null(reference_lines)) {
    return(NULL)
  }

  if (!"date" %in% names(reference_lines)) {
    stop("`reference_lines` must contain a `date` column.", call. = FALSE)
  }

  reference_lines$date <- as.Date(reference_lines$date)
  if (anyNA(reference_lines$date)) {
    stop("All `reference_lines$date` values must be valid dates.", call. = FALSE)
  }

  if (!"label" %in% names(reference_lines)) {
    reference_lines$label <- format_date_label(reference_lines$date)
  }

  if (!"label_y" %in% names(reference_lines)) {
    reference_lines$label_y <- default_column(style$date_label_y, nrow(reference_lines))
  }

  if (!"lwd" %in% names(reference_lines)) {
    reference_lines$lwd <- default_column(style$reference_line_lwd, nrow(reference_lines))
  }

  reference_lines
}

draw_change_line <- function(change_date, change_type, policy_term_months, view_start, view_end, style) {
  if (change_type == "vertical") {
    graphics::segments(
      date_num(change_date), 0,
      date_num(change_date), 100,
      col = style$change_col,
      lty = style$change_lty,
      lwd = style$change_lwd
    )
    return(invisible(NULL))
  }

  line_end <- add_months(change_date, policy_term_months)
  xa <- max(date_num(change_date), date_num(view_start))
  xb <- min(date_num(line_end), date_num(view_end))

  if (xa >= xb) {
    return(invisible(NULL))
  }

  width <- date_num(line_end) - date_num(change_date)
  ya <- 100 * (xa - date_num(change_date)) / width
  yb <- 100 * (xb - date_num(change_date)) / width

  graphics::segments(xa, ya, xb, yb, col = style$change_col, lty = style$change_lty, lwd = style$change_lwd)
}

format_date_label <- function(date) {
  date <- as.Date(date)
  format(date, "%Y-%m-%d")
}

draw_plot_frame <- function(view_start, view_end, style) {
  graphics::rect(
    date_num(view_start), 0,
    date_num(view_end), 100,
    border = style$border_col,
    lwd = style$border_lwd
  )

  for (y in c(25, 50, 75, 100)) {
    graphics::segments(
      date_num(view_start), y,
      date_num(view_end), y,
      col = style$major_grid_col,
      lty = style$major_grid_lty,
      lwd = style$major_grid_lwd
    )
  }
}

draw_date_labels <- function(dates, view_start, view_end, style) {
  dates <- as.Date(dates)
  dates <- unique(dates[dates >= view_start & dates <= view_end])

  if (!length(dates)) {
    return(invisible(NULL))
  }

  graphics::par(xpd = NA)
  graphics::text(
    date_num(dates),
    style$date_label_y,
    labels = format_date_label(dates),
    cex = style$date_cex
  )
  graphics::par(xpd = FALSE)

  invisible(NULL)
}

draw_policy_lines <- function(
    policies,
    hide_after_date,
    highlight_earned_start,
    highlight_earned_end,
    geometry,
    view_start,
    view_end,
    style
) {
  if (is.null(policies)) {
    return(invisible(NULL))
  }

  for (i in seq_len(nrow(policies))) {
    policy_end <- if (is.null(hide_after_date)) {
      policies$end[i]
    } else {
      min(policies$end[i], hide_after_date)
    }

    xa <- max(date_num(policies$start[i]), date_num(view_start))
    xb <- min(date_num(policy_end), date_num(view_end))

    if (xa >= xb) {
      next
    }

    width <- date_num(policies$end[i]) - date_num(policies$start[i])
    ya <- 100 * (xa - date_num(policies$start[i])) / width
    yb <- 100 * (xb - date_num(policies$start[i])) / width

    graphics::segments(xa, ya, xb, yb, col = style$policy_line_col, lwd = style$policy_line_lwd)

    if (!is.null(highlight_earned_start)) {
      highlight_entire_policy <- geometry == "parallelogram" &&
        policies$start[i] >= highlight_earned_start &&
        policies$start[i] < highlight_earned_end

      if (highlight_entire_policy) {
        highlight_start <- max(policies$start[i], view_start)
        highlight_end <- min(policy_end, view_end)
      } else if (geometry == "parallelogram") {
        highlight_start <- policies$start[i]
        highlight_end <- policies$start[i]
      } else {
        highlight_start <- max(
          policies$start[i],
          highlight_earned_start,
          view_start
        )
        highlight_end <- min(
          policy_end,
          highlight_earned_end,
          view_end
        )
      }

      if (highlight_start < highlight_end) {
        highlight_xa <- date_num(highlight_start)
        highlight_xb <- date_num(highlight_end)
        highlight_ya <- 100 * (highlight_xa - date_num(policies$start[i])) / width
        highlight_yb <- 100 * (highlight_xb - date_num(policies$start[i])) / width

        graphics::segments(
          highlight_xa,
          highlight_ya,
          highlight_xb,
          highlight_yb,
          col = style$policy_line_col,
          lwd = 3 * style$policy_line_lwd
        )
      }
    }

    if (nzchar(policies$label[i])) {
      label_y <- policies$label_y[i]
      label_x <- date_num(policies$start[i]) + (label_y / 100) * width

      if (
        label_x >= date_num(view_start) &&
          label_x <= date_num(view_end) &&
          label_x <= date_num(policy_end)
      ) {
        graphics::text(label_x, label_y, policies$label[i], cex = policies$label_cex[i])
      }
    }
  }

  invisible(NULL)
}

draw_points <- function(points) {
  if (is.null(points)) {
    return(invisible(NULL))
  }

  graphics::par(xpd = NA)
  graphics::points(date_num(points$date), points$y, pch = points$pch, cex = points$cex)
  graphics::par(xpd = FALSE)
  invisible(NULL)
}

draw_reference_lines <- function(reference_lines, style) {
  if (is.null(reference_lines)) {
    return(invisible(NULL))
  }

  for (i in seq_len(nrow(reference_lines))) {
    graphics::segments(
      date_num(reference_lines$date[i]), 0,
      date_num(reference_lines$date[i]), 100,
      col = style$reference_line_col,
      lwd = reference_lines$lwd[i]
    )

    if (nzchar(reference_lines$label[i])) {
      graphics::par(xpd = NA)
      graphics::text(
        date_num(reference_lines$date[i]),
        reference_lines$label_y[i],
        reference_lines$label[i],
        cex = style$reference_label_cex,
        font = 2
      )
      graphics::par(xpd = FALSE)
    }
  }

  invisible(NULL)
}

draw_rate_level_base <- function(
    periods,
    geometry,
    policy_term_months,
    view_start,
    view_end,
    period_months,
    prefix,
    style,
    policies,
    points,
    reference_lines,
    minor_grid_months,
    y_axis_label,
    show_date_labels,
    show_period_fill,
    show_period_labels,
    hide_after_date,
    highlight_earned_start,
    highlight_earned_end
) {
  graphics::plot(
    NA,
    xlim = date_num(c(view_start, view_end)),
    ylim = c(0, 100),
    axes = FALSE,
    xlab = "",
    ylab = "",
    xaxs = "i",
    yaxs = "i"
  )

  if (show_period_fill) {
    shades <- grDevices::gray(seq(style$fill_start, style$fill_end, length.out = nrow(periods)))

    for (i in seq_len(nrow(periods))) {
      draw_period_polygon(
        periods$start[i],
        periods$end[i],
        geometry,
        policy_term_months,
        col = shades[i],
        border = NA,
        lwd = 1
      )
    }
  }

  draw_minor_grid(
    start_date = periods$start[1],
    view_start = view_start,
    view_end = view_end,
    minor_grid_months = minor_grid_months,
    geometry = geometry,
    policy_term_months = policy_term_months,
    col = style$minor_grid_col,
    lwd = style$minor_grid_lwd
  )

  draw_plot_frame(view_start, view_end, style)

  for (i in seq_len(nrow(periods))) {
    draw_period_polygon(
      periods$start[i],
      periods$end[i],
      geometry,
      policy_term_months,
      col = NA,
      border = style$period_boundary_col,
      lwd = style$period_boundary_lwd
    )

    if (show_period_labels) {
      label_x <- period_label_x(periods$start[i], periods$end[i], geometry, policy_term_months)
      if (label_x >= date_num(view_start) && label_x <= date_num(view_end)) {
        graphics::par(xpd = NA)
        graphics::text(
          x = label_x,
          y = style$top_label_y,
          labels = format_period_label(periods$start[i], period_months, prefix),
          cex = style$period_cex
        )
        graphics::par(xpd = FALSE)
      }
    }
  }

  graphics::axis(
    2,
    at = c(0, 25, 50, 75, 100),
    labels = paste0(c(0, 25, 50, 75, 100), "%"),
    las = 1
  )
  graphics::mtext(y_axis_label, side = 2, line = 3.6)

  tick_dates <- unique(c(periods$start, periods$end))
  tick_x <- date_num(tick_dates)
  tick_x <- tick_x[tick_x >= date_num(view_start) & tick_x <= date_num(view_end)]
  graphics::par(xpd = NA)
  draw_period_ticks(tick_x, style$bottom_tick_length, style$top_tick_length)
  graphics::par(xpd = FALSE)

  if (show_date_labels) {
    draw_date_labels(tick_dates, view_start, view_end, style)
  }

  draw_policy_lines(
    policies,
    hide_after_date,
    highlight_earned_start,
    highlight_earned_end,
    geometry,
    view_start,
    view_end,
    style
  )
  draw_reference_lines(reference_lines, style)
  draw_points(points)
}

draw_parallelogram_method <- function(
    changes,
    zone_labels,
    analyzed_start,
    analyzed_end,
    geometry,
    policy_term_months,
    view_start,
    view_end,
    style
) {
  if (!is.null(changes)) {
    for (i in seq_len(nrow(changes))) {
      change_date <- changes$date[i]

      draw_change_line(
        change_date = change_date,
        change_type = changes$type[i],
        policy_term_months = policy_term_months,
        view_start = view_start,
        view_end = view_end,
        style = style
      )

      graphics::par(xpd = NA)
      if (!is.na(changes$date_y[i])) {
        graphics::text(date_num(change_date), changes$date_y[i], format(change_date, "%Y-%m-%d"), cex = style$date_cex)
      }

      if (!is.na(changes$label_y[i]) && nzchar(changes$label[i])) {
        graphics::text(date_num(change_date), changes$label_y[i], changes$label[i], cex = style$change_cex, adj = c(0.5, 1))
      }
      graphics::par(xpd = FALSE)
    }
  }

  if (!is.null(zone_labels)) {
    for (i in seq_len(nrow(zone_labels))) {
      graphics::text(zone_labels$x[i], zone_labels$y[i], zone_labels$label[i], cex = zone_labels$cex[i])
    }
  }

  if (!is.null(analyzed_start)) {
    draw_analyzed_outline(
      analyzed_start,
      analyzed_end,
      geometry,
      policy_term_months,
      style
    )
  }
}

#' Draw a Rate-Level / Parallelogram Diagram
#'
#' Draws the shared ACT-4105 rate-level, benefit-level, law-change, and
#' parallelogram-style diagram. It can also draw the policy-line exposure
#' diagrams used to introduce calendar-year and policy-year compilation.
#'
#' @param start_date Start date of the displayed experience periods.
#' @param end_date End date of the displayed experience periods.
#' @param experience_period One of `"calendar"`, `"policy"`, `"accident"`, or
#'   `"reporting"`. This determines the period label prefix (`AC`, `AA`, `AP`,
#'   `AR`) and the period shape. Only policy periods are parallelograms.
#' @param policy_term_months Policy term in months. This controls diagonal
#'   change lines and policy-period parallelogram width.
#' @param period_months Number of months in each displayed period. Use `12` for
#'   annual diagrams and `3` for quarterly diagrams.
#' @param changes Optional data frame describing rate or benefit changes. Must
#'   contain `date`; may contain `type` (`"diagonal"` or `"vertical"`), `label`,
#'   `date_y`, and `label_y`.
#' @param zone_labels Optional data frame for zone labels. Must contain either
#'   `date` or `x`, and `label`; may contain `y` and `cex`.
#' @param policies Optional data frame of individual policy lines. Must contain
#'   `start`; may contain `end`, `label`, `label_y`, and `label_cex`. If `end`
#'   is omitted, it defaults to `start + policy_term_months`.
#' @param hide_after_date Optional date after which individual policy lines are
#'   hidden. Policies are drawn only up to this date; policies starting after
#'   this date are not drawn. Their labels are also hidden when they fall after
#'   the cutoff.
#' @param highlight_earned_start,highlight_earned_end Optional start and end
#'   dates of the interval whose portions of policy lines should be emphasized.
#'   For calendar, accident, and reporting periods, the intersecting portions
#'   are drawn with three times the normal line width. For policy periods, all
#'   policies starting in the interval are drawn in full with three times the
#'   normal line width. The two dates must be supplied together.
#' @param points Optional data frame of point markers. Must contain `date`; may
#'   contain `y`, `pch`, and `cex`.
#' @param reference_lines Optional data frame of solid vertical reference lines.
#'   Must contain `date`; may contain `label`, `label_y`, and `lwd`.
#' @param analyzed_start,analyzed_end Optional period start/end dates to outline
#'   as the analyzed period. If `analyzed_end` is omitted, it defaults to
#'   `analyzed_start + period_months`.
#' @param view_start,view_end Optional x-axis limits. Use these only to crop the
#'   same shared diagram when the displayed periods extend beyond the useful
#'   part of the exercise.
#' @param minor_grid_months Optional number of months between minor guide lines.
#'   Use `1` to show monthly guides.
#' @param y_axis_label Label shown on the y-axis.
#' @param show_date_labels Whether to show labels below period-boundary ticks.
#' @param show_period_fill,show_period_labels Whether to show period shading and
#'   period labels. These default to the historical rate-level diagram behavior.
#' @param mar Plot margins passed to `graphics::par()`.
#'
#' @return Invisibly returns `NULL`, called for its plotting side effects.
#' @export
rate_level_diagram <- function(
    start_date,
    end_date,
    experience_period = c("calendar", "policy", "accident", "reporting"),
    policy_term_months = 12,
    period_months = 12,
    changes = NULL,
    zone_labels = NULL,
    policies = NULL,
    points = NULL,
    reference_lines = NULL,
    analyzed_start = NULL,
    analyzed_end = NULL,
    view_start = NULL,
    view_end = NULL,
    minor_grid_months = NULL,
    y_axis_label = "% du terme de police expiré",
    show_date_labels = FALSE,
    show_period_fill = TRUE,
    show_period_labels = TRUE,
    mar = c(6.6, 5.4, 3.0, 2.4),
    hide_after_date = NULL,
    highlight_earned_start = NULL,
    highlight_earned_end = NULL
) {
  experience_period <- match.arg(experience_period)
  geometry <- experience_geometry(experience_period)
  prefix <- experience_prefix(experience_period)
  style <- rate_level_style()

  start_date <- normalize_date(start_date, "start_date")
  end_date <- normalize_date(end_date, "end_date")

  if (end_date <= start_date) {
    stop("`end_date` must be later than `start_date`.", call. = FALSE)
  }

  validate_positive_months(policy_term_months, "policy_term_months")
  validate_positive_months(period_months, "period_months")
  validate_positive_months(minor_grid_months, "minor_grid_months", allow_null = TRUE)

  analyzed_start <- if (is.null(analyzed_start)) NULL else normalize_date(analyzed_start, "analyzed_start")
  analyzed_end <- if (is.null(analyzed_end)) {
    if (is.null(analyzed_start)) NULL else add_months(analyzed_start, period_months)
  } else {
    normalize_date(analyzed_end, "analyzed_end")
  }

  hide_after_date <- if (is.null(hide_after_date)) {
    NULL
  } else {
    normalize_date(hide_after_date, "hide_after_date")
  }

  if (xor(is.null(highlight_earned_start), is.null(highlight_earned_end))) {
    stop(
      "`highlight_earned_start` and `highlight_earned_end` must be supplied together.",
      call. = FALSE
    )
  }

  highlight_earned_start <- if (is.null(highlight_earned_start)) {
    NULL
  } else {
    normalize_date(highlight_earned_start, "highlight_earned_start")
  }
  highlight_earned_end <- if (is.null(highlight_earned_end)) {
    NULL
  } else {
    normalize_date(highlight_earned_end, "highlight_earned_end")
  }

  if (!is.null(highlight_earned_start) && highlight_earned_end <= highlight_earned_start) {
    stop("`highlight_earned_end` must be later than `highlight_earned_start`.", call. = FALSE)
  }

  view_start <- if (is.null(view_start)) start_date else normalize_date(view_start, "view_start")
  view_end <- if (is.null(view_end)) {
    if (geometry == "parallelogram") add_months(end_date, policy_term_months) else end_date
  } else {
    normalize_date(view_end, "view_end")
  }

  if (view_end <= view_start) {
    stop("`view_end` must be later than `view_start`.", call. = FALSE)
  }

  periods <- build_periods(start_date, end_date, period_months)
  changes <- normalize_changes(changes, style)
  zone_labels <- normalize_zone_labels(zone_labels, style$zone_cex)
  policies <- normalize_policies(policies, policy_term_months, style$policy_label_cex)
  points <- normalize_points(points, style$point_cex)
  reference_lines <- normalize_reference_lines(reference_lines, style)

  old_par <- graphics::par(mar = mar, xpd = FALSE)
  on.exit(graphics::par(old_par), add = TRUE)

  draw_rate_level_base(
    periods = periods,
    geometry = geometry,
    policy_term_months = policy_term_months,
    view_start = view_start,
    view_end = view_end,
    period_months = period_months,
    prefix = prefix,
    style = style,
    policies = policies,
    hide_after_date = hide_after_date,
    points = points,
    reference_lines = reference_lines,
    minor_grid_months = minor_grid_months,
    y_axis_label = y_axis_label,
    show_date_labels = show_date_labels,
    show_period_fill = show_period_fill,
    show_period_labels = show_period_labels,
    highlight_earned_start = highlight_earned_start,
    highlight_earned_end = highlight_earned_end
  )

  draw_parallelogram_method(
    changes = changes,
    zone_labels = zone_labels,
    analyzed_start = analyzed_start,
    analyzed_end = analyzed_end,
    geometry = geometry,
    policy_term_months = policy_term_months,
    view_start = view_start,
    view_end = view_end,
    style = style
  )

  invisible(NULL)
}
