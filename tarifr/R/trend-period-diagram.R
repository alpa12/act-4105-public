period_midpoint_date <- function(start_date, end_date) {
  start_date <- as.Date(start_date)
  end_date <- as.Date(end_date)
  start_lt <- as.POSIXlt(start_date)
  end_lt <- as.POSIXlt(end_date)
  month_diff <- 12 * ((end_lt$year + 1900) - (start_lt$year + 1900)) +
    (end_lt$mon - start_lt$mon)

  if (start_lt$mday == end_lt$mday && month_diff %% 2 == 0) {
    return(add_months(start_date, month_diff / 2))
  }

  as.Date(round(mean(date_num(c(start_date, end_date)))), origin = "1970-01-01")
}

format_projection_date <- function(date) {
  format(as.Date(date), "%Y-%m-%d")
}

format_axis_date <- function(date) {
  format_projection_date(date)
}

normalize_trend_axis_dates <- function(axis_dates) {
  if (is.null(axis_dates)) {
    return(as.Date(character()))
  }

  dates <- tryCatch(
    as.Date(axis_dates),
    error = function(error) {
      stop("`axis_dates` must contain valid dates.", call. = FALSE)
    }
  )

  if (anyNA(dates)) {
    stop("`axis_dates` must contain valid dates.", call. = FALSE)
  }

  dates
}

default_experience_average_date <- function(experience_start,
                                            experience_end,
                                            experience_period_type,
                                            trend_type,
                                            policy_term_months) {
  if (trend_type == "premium") {
    if (experience_period_type == "calendar") {
      return(add_months(experience_start, (12 - policy_term_months) / 2))
    }

    return(period_midpoint_date(experience_start, experience_end))
  }

  if (experience_period_type == "policy") {
    return(add_months(period_midpoint_date(experience_start, experience_end), policy_term_months / 2))
  }

  period_midpoint_date(experience_start, experience_end)
}

default_prospective_average_date <- function(prospective_start,
                                             prospective_end,
                                             trend_type,
                                             policy_term_months) {
  written_midpoint <- period_midpoint_date(prospective_start, prospective_end)

  if (trend_type == "loss") {
    return(add_months(written_midpoint, policy_term_months / 2))
  }

  written_midpoint
}

default_period_label <- function(start_date, period_type) {
  prefix <- year_method_prefix(period_type)

  paste(prefix, format(as.Date(start_date), "%Y"))
}

trend_period_style <- function() {
  rate_style <- rate_level_style()

  list(
    band_fill = grDevices::adjustcolor("black", alpha.f = 0.08),
    band_border = rate_style$border_col,
    guide = grDevices::adjustcolor(rate_style$border_col, alpha.f = 0.62),
    grid = rate_style$major_grid_col,
    axis_lwd = rate_style$border_lwd,
    guide_lwd = 1.1,
    interval_arrow_lwd = 3.0,
    marker_arrow_lwd = 2.4,
    band_height = 100
  )
}

draw_timeline_axis <- function(xlim_start, xlim_end, axis_ticks, date_labels, date_cex, style) {
  x0 <- date_num(xlim_start)
  x1 <- date_num(xlim_end)

  graphics::segments(x0, 0, x1, 0, lwd = style$axis_lwd)
  graphics::segments(x0, 0, x0, style$band_height, lwd = style$axis_lwd)

  graphics::abline(h = c(50, 100), lty = 2, lwd = style$guide_lwd, col = style$grid)
  graphics::axis(2, at = c(50, 100), labels = c("50%", "100%"), las = 1)

  tick_x <- date_num(axis_ticks)
  draw_vertical_ticks(tick_x, -5, 5, lwd = 0.8)

  if (length(date_labels)) {
    graphics::text(
      date_num(date_labels),
      -14,
      labels = vapply(date_labels, format_axis_date, character(1)),
      cex = date_cex
    )
  }
}

draw_projection_marker <- function(date, label, y, cex, adj, style) {
  x <- date_num(date)

  graphics::arrows(x, y + 13, x, 0, length = 0.10, lwd = style$marker_arrow_lwd,
                   xpd = NA)
  graphics::text(x, y, label, cex = cex, font = 2, adj = adj, xpd = NA)
}

draw_interval_arrow <- function(start_date, end_date, y, style) {
  graphics::arrows(
    date_num(start_date), y,
    date_num(end_date), y,
    code = 3,
    length = 0.09,
    lwd = style$interval_arrow_lwd,
    xpd = NA
  )
}

draw_trend_period_box <- function(start_date, end_date, label, label_cex, style) {
  x0 <- date_num(start_date)
  x1 <- date_num(end_date)

  graphics::rect(x0, 0, x1, style$band_height, col = style$band_fill, border = style$band_border,
                 lwd = style$axis_lwd)
  graphics::text(mean(c(x0, x1)), style$band_height + 12, labels = label, cex = label_cex)
}

draw_policy_trend_band <- function(start_date, end_date, policy_term_months,
                                   label, label_cex, style) {
  term_end <- add_months(end_date, policy_term_months)

  graphics::polygon(
    x = date_num(c(
      start_date,
      end_date,
      term_end,
      add_months(start_date, policy_term_months)
    )),
    y = c(0, 0, style$band_height, style$band_height),
    col = style$band_fill,
    border = style$band_border,
    lwd = style$axis_lwd
  )
  graphics::text(
    mean(date_num(c(start_date, term_end))),
    style$band_height + 12,
    labels = label,
    cex = label_cex
  )
}

draw_trend_factor_interval <- function(start_date, end_date, label, y, cex, style) {
  graphics::arrows(
    date_num(start_date), y,
    date_num(end_date), y,
    code = 2,
    length = 0.07,
    lwd = style$interval_arrow_lwd,
    xpd = NA
  )
  graphics::text(
    mean(date_num(c(start_date, end_date))),
    y + 16,
    labels = label,
    cex = cex,
    xpd = NA
  )
}

draw_term_guides <- function(start_dates, policy_term_months, xlim_start, xlim_end, style) {
  for (start_date in as.Date(start_dates)) {
    end_date <- add_months(start_date, policy_term_months)
    xa <- max(date_num(start_date), date_num(xlim_start))
    xb <- min(date_num(end_date), date_num(xlim_end))

    if (xa < xb) {
      full_width <- date_num(end_date) - date_num(start_date)
      ya <- 100 * (xa - date_num(start_date)) / full_width
      yb <- 100 * (xb - date_num(start_date)) / full_width
      graphics::segments(xa, ya * style$band_height / 100, xb, yb * style$band_height / 100, lty = 2,
                         col = style$guide, lwd = style$guide_lwd)
    }
  }
}

#' Draw a Premium Trend Period Diagram
#'
#' Draws the date-calculation diagram used to identify historical and
#' prospective average dates for premium or loss trend periods.
#'
#' @param experience_start,experience_end Start and end dates of the historical
#'   experience period.
#' @param prospective_start,prospective_end Start and end dates of the
#'   prospective period. If `prospective_end` is omitted, it is computed from
#'   `prospective_start` and `rate_period_months`.
#' @param experience_period_type Historical compilation basis: `"calendar"`,
#'   `"policy"`, or `"accident"`.
#' @param trend_type Whether the diagram is for `"premium"` trend or `"loss"`
#'   trend. This controls the default average-date calculations.
#' @param rate_period_months Length of the prospective rate period, in months.
#' @param policy_term_months Policy term in months.
#' @param experience_average_date,prospective_average_date Dates marked as the
#'   beginning and end of the trend period. If omitted, they are calculated from
#'   `experience_period_type`, `trend_type`, and `policy_term_months`.
#' @param experience_label,prospective_label Labels shown above each period.
#' @param experience_average_detail,prospective_average_detail Retained for
#'   compatibility; no longer shown in the simplified diagram.
#' @param experience_average_label,prospective_average_label Labels shown as
#'   `Début : ...` and `Fin : ...`. If omitted, the average dates are formatted.
#' @param xlim_start,xlim_end Optional plot limits.
#' @param axis_dates Optional dates added as labeled ticks on the timeline.
#'   This is useful for instructional reference dates that are not period
#'   boundaries, such as the beginning of each calendar year.
#' @param y_axis_label Label shown on the y-axis.
#' @param date_cex,label_cex Text sizes for date and period labels.
#'
#' @return Invisibly returns `NULL`, called for its plotting side effects.
#' @export
trend_period_diagram <- function(
    experience_start,
    experience_end,
    prospective_start,
    prospective_end = NULL,
    experience_period_type = c("calendar", "policy", "accident"),
    trend_type = c("premium", "loss"),
    rate_period_months = 12,
    policy_term_months = 12,
    experience_average_date = NULL,
    prospective_average_date = NULL,
    experience_label = NULL,
    prospective_label = NULL,
    experience_average_detail = NULL,
    prospective_average_detail = NULL,
    experience_average_label = NULL,
    prospective_average_label = NULL,
    xlim_start = NULL,
    xlim_end = NULL,
    axis_dates = NULL,
    y_axis_label = NULL,
    date_cex = 0.9,
    label_cex = 1.0
) {
  experience_period_type <- match.arg(experience_period_type)
  trend_type <- match.arg(trend_type)

  experience_start <- normalize_date(experience_start, "experience_start")
  experience_end <- normalize_date(experience_end, "experience_end")
  prospective_start <- normalize_date(prospective_start, "prospective_start")

  validate_positive_months(rate_period_months, "rate_period_months")
  validate_positive_months(policy_term_months, "policy_term_months")

  prospective_end <- if (is.null(prospective_end)) {
    add_months(prospective_start, rate_period_months)
  } else {
    normalize_date(prospective_end, "prospective_end")
  }

  if (experience_end <= experience_start) {
    stop("`experience_end` must be later than `experience_start`.", call. = FALSE)
  }

  if (prospective_end <= prospective_start) {
    stop("`prospective_end` must be later than `prospective_start`.", call. = FALSE)
  }

  experience_average_date <- if (is.null(experience_average_date)) {
    default_experience_average_date(
      experience_start = experience_start,
      experience_end = experience_end,
      experience_period_type = experience_period_type,
      trend_type = trend_type,
      policy_term_months = policy_term_months
    )
  } else {
    normalize_date(experience_average_date, "experience_average_date")
  }

  prospective_average_date <- if (is.null(prospective_average_date)) {
    default_prospective_average_date(
      prospective_start = prospective_start,
      prospective_end = prospective_end,
      trend_type = trend_type,
      policy_term_months = policy_term_months
    )
  } else {
    normalize_date(prospective_average_date, "prospective_average_date")
  }

  xlim_start <- if (is.null(xlim_start)) {
    if (experience_period_type == "calendar" && trend_type == "premium") {
      add_months(experience_start, -policy_term_months)
    } else if (experience_period_type == "policy") {
      experience_start
    } else {
      add_months(experience_start, -12)
    }
  } else {
    normalize_date(xlim_start, "xlim_start")
  }

  xlim_end <- if (is.null(xlim_end)) {
    add_months(prospective_end, policy_term_months)
  } else {
    normalize_date(xlim_end, "xlim_end")
  }

  if (xlim_end <= xlim_start) {
    stop("`xlim_end` must be later than `xlim_start`.", call. = FALSE)
  }

  axis_dates <- normalize_trend_axis_dates(axis_dates)

  experience_label <- if (is.null(experience_label)) {
    default_period_label(experience_start, experience_period_type)
  } else {
    experience_label
  }

  prospective_label <- if (is.null(prospective_label)) {
    paste(year_method_prefix("policy"), format(as.Date(prospective_start), "%Y"))
  } else {
    prospective_label
  }

  experience_average_label <- if (is.null(experience_average_label)) {
    format_projection_date(experience_average_date)
  } else {
    experience_average_label
  }

  prospective_average_label <- if (is.null(prospective_average_label)) {
    format_projection_date(prospective_average_date)
  } else {
    prospective_average_label
  }

  y_axis_label <- if (is.null(y_axis_label)) {
    if (trend_type == "loss") "" else "% du terme expiré"
  } else {
    y_axis_label
  }

  axis_ticks <- sort(unique(as.Date(c(
    experience_start,
    experience_end,
    prospective_start,
    prospective_end,
    axis_dates
  ))))
  axis_ticks <- axis_ticks[axis_ticks >= xlim_start & axis_ticks <= xlim_end]

  style <- trend_period_style()
  marker_x <- date_num(c(experience_average_date, prospective_average_date))
  span <- diff(date_num(c(xlim_start, xlim_end)))
  markers_close <- abs(diff(marker_x)) < 0.20 * span
  marker_y <- if (markers_close) c(-34, -56) else c(-34, -34)
  axis_date_labels <- axis_ticks[
    !(axis_ticks %in% c(experience_average_date, prospective_average_date))
  ]

  old_par <- graphics::par(mar = c(0.15, 4.4, 0.15, 0.15), xpd = NA)
  on.exit(graphics::par(old_par), add = TRUE)

  graphics::plot(
    NA,
    xlim = date_num(c(xlim_start, xlim_end)),
    ylim = c(if (markers_close) -66 else -44, 116),
    axes = FALSE,
    xlab = "",
    ylab = "",
    xaxs = "i",
    yaxs = "i"
  )

  draw_timeline_axis(
    xlim_start = xlim_start,
    xlim_end = xlim_end,
    axis_ticks = axis_ticks,
    date_labels = axis_date_labels,
    date_cex = date_cex,
    style = style
  )

  if (nzchar(y_axis_label)) {
    graphics::mtext(y_axis_label, side = 2, line = 3.2, cex = label_cex)
  }

  experience_guide_start <- if (experience_period_type == "policy") {
    experience_start
  } else {
    add_months(experience_start, -policy_term_months)
  }

  draw_term_guides(
    start_dates = c(experience_guide_start, prospective_start, prospective_end),
    policy_term_months = policy_term_months,
    xlim_start = xlim_start,
    xlim_end = xlim_end,
    style = style
  )

  if (experience_period_type == "policy") {
    draw_policy_trend_band(
      experience_start,
      experience_end,
      policy_term_months,
      experience_label,
      label_cex,
      style
    )
  } else {
    draw_trend_period_box(experience_start, experience_end, experience_label, label_cex, style)
  }
  draw_policy_trend_band(
    prospective_start,
    prospective_end,
    policy_term_months,
    prospective_label,
    label_cex,
    style
  )
  experience_interval_start <- if (experience_period_type == "calendar") {
    add_months(experience_start, -policy_term_months)
  } else {
    experience_start
  }

  draw_interval_arrow(
    start_date = experience_interval_start,
    end_date = experience_end,
    y = 13,
    style = style
  )
  draw_interval_arrow(
    start_date = prospective_start,
    end_date = prospective_end,
    y = 13,
    style = style
  )

  draw_projection_marker(
    date = experience_average_date,
    label = paste0("Début\n", experience_average_label),
    y = marker_y[1],
    cex = date_cex,
    adj = 0.5,
    style = style
  )

  draw_projection_marker(
    date = prospective_average_date,
    label = paste0("Fin\n", prospective_average_label),
    y = marker_y[2],
    cex = date_cex,
    adj = 0.5,
    style = style
  )

  invisible(NULL)
}
