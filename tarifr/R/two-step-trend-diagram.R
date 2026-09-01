#' Draw a Two-Step Premium Trend Diagram
#'
#' Draws a compact timeline for two-step premium trending. The diagram shows
#' the historical calendar period, the latest current premium level, and the
#' prospective policy period used for the projected trend factor.
#'
#' @param experience_start,experience_end Start and end dates of the historical
#'   experience period.
#' @param current_date Date of the latest premium level used by the current
#'   trend factor.
#' @param prospective_start,prospective_end Start and end dates of the
#'   prospective policy period. If `prospective_end` is omitted, it is computed
#'   from `prospective_start` and `rate_period_months`.
#' @param policy_term_months Policy term in months.
#' @param rate_period_months Length of the prospective rate period, in months.
#' @param experience_average_date,prospective_average_date Dates at the start
#'   of the current and projected trend intervals. Defaults are calculated from
#'   the period bounds and the policy term.
#' @param experience_label,prospective_label Labels displayed above the
#'   historical and prospective periods.
#' @param current_factor_label,projected_factor_label Labels displayed above
#'   the two trend intervals.
#' @param current_marker_label Label used for the current-date marker.
#' @param xlim_start,xlim_end Optional plot limits. By default, the plot starts
#'   one policy term before the historical period to show the earned-exposure
#'   guide entering that period.
#' @param axis_dates Optional dates added as labeled ticks on the timeline.
#' @param y_axis_label Label shown on the y-axis.
#' @param date_cex,label_cex Text sizes for date and period labels.
#'
#' @return Invisibly returns `NULL`, called for its plotting side effects.
#' @export
two_step_trend_diagram <- function(
    experience_start,
    experience_end,
    current_date,
    prospective_start,
    prospective_end = NULL,
    policy_term_months = 12,
    rate_period_months = 12,
    experience_average_date = NULL,
    prospective_average_date = NULL,
    experience_label = NULL,
    prospective_label = NULL,
    current_factor_label = "Facteur de tendance courante",
    projected_factor_label = "Facteur de tendance projetée",
    current_marker_label = "Niveau courant",
    xlim_start = NULL,
    xlim_end = NULL,
    axis_dates = NULL,
    y_axis_label = "% du terme expiré",
    date_cex = 0.82,
    label_cex = 1.0
) {
  experience_start <- normalize_date(experience_start, "experience_start")
  experience_end <- normalize_date(experience_end, "experience_end")
  current_date <- normalize_date(current_date, "current_date")
  prospective_start <- normalize_date(prospective_start, "prospective_start")

  if (experience_end <= experience_start) {
    stop("`experience_end` must be later than `experience_start`.", call. = FALSE)
  }

  validate_positive_months(policy_term_months, "policy_term_months")
  validate_positive_months(rate_period_months, "rate_period_months")

  prospective_end <- if (is.null(prospective_end)) {
    add_months(prospective_start, rate_period_months)
  } else {
    normalize_date(prospective_end, "prospective_end")
  }

  if (prospective_end <= prospective_start) {
    stop("`prospective_end` must be later than `prospective_start`.", call. = FALSE)
  }

  experience_average_date <- if (is.null(experience_average_date)) {
    add_months(experience_start, (12 - policy_term_months) / 2)
  } else {
    normalize_date(experience_average_date, "experience_average_date")
  }

  prospective_average_date <- if (is.null(prospective_average_date)) {
    period_midpoint_date(prospective_start, prospective_end)
  } else {
    normalize_date(prospective_average_date, "prospective_average_date")
  }

  if (current_date <= experience_average_date) {
    stop("`current_date` must be later than `experience_average_date`.", call. = FALSE)
  }

  if (prospective_average_date <= current_date) {
    stop("`prospective_average_date` must be later than `current_date`.", call. = FALSE)
  }

  xlim_start <- if (is.null(xlim_start)) {
    add_months(experience_start, -policy_term_months)
  } else {
    normalize_date(xlim_start, "xlim_start")
  }

  xlim_end <- if (is.null(xlim_end)) {
    add_months(prospective_end, policy_term_months + 3)
  } else {
    normalize_date(xlim_end, "xlim_end")
  }

  if (xlim_end <= xlim_start) {
    stop("`xlim_end` must be later than `xlim_start`.", call. = FALSE)
  }

  axis_dates <- normalize_trend_axis_dates(axis_dates)

  experience_label <- if (is.null(experience_label)) {
    paste(year_method_prefix("calendar"), format(experience_start, "%Y"))
  } else {
    experience_label
  }

  prospective_label <- if (is.null(prospective_label)) {
    paste(year_method_prefix("policy"), format(prospective_start, "%Y"))
  } else {
    prospective_label
  }

  style <- trend_period_style()
  axis_ticks <- sort(unique(as.Date(c(
    xlim_start,
    experience_start,
    experience_end,
    prospective_start,
    prospective_end,
    axis_dates
  ))))
  axis_ticks <- axis_ticks[axis_ticks >= xlim_start & axis_ticks <= xlim_end]
  marker_dates <- c(experience_average_date, current_date, prospective_average_date)
  axis_date_labels <- axis_ticks[!(axis_ticks %in% marker_dates)]

  old_par <- graphics::par(mar = c(2.6, 4.6, 1.6, 0.25), xpd = NA)
  on.exit(graphics::par(old_par), add = TRUE)

  graphics::plot(
    NA,
    xlim = date_num(c(xlim_start, xlim_end)),
    ylim = c(-74, 174),
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
  graphics::mtext(y_axis_label, side = 2, line = 3.2, cex = label_cex)

  draw_term_guides(
    start_dates = add_months(experience_start, -policy_term_months),
    policy_term_months = policy_term_months,
    xlim_start = xlim_start,
    xlim_end = xlim_end,
    style = style
  )
  draw_trend_period_box(
    experience_start,
    experience_end,
    experience_label,
    label_cex,
    style
  )

  draw_policy_trend_band(
    prospective_start,
    prospective_end,
    policy_term_months,
    prospective_label,
    label_cex,
    style
  )
  draw_trend_factor_interval(
    experience_average_date,
    current_date,
    current_factor_label,
    y = 132,
    cex = date_cex,
    style = style
  )
  draw_trend_factor_interval(
    current_date,
    prospective_average_date,
    projected_factor_label,
    y = 132,
    cex = date_cex,
    style = style
  )

  draw_projection_marker(
    experience_average_date,
    paste0("Début\n", format_projection_date(experience_average_date)),
    y = -36,
    cex = date_cex,
    adj = 0.5,
    style = style
  )
  draw_projection_marker(
    current_date,
    paste0(current_marker_label, "\n", format_projection_date(current_date)),
    y = -62,
    cex = date_cex,
    adj = 0.5,
    style = style
  )
  draw_projection_marker(
    prospective_average_date,
    paste0("Fin\n", format_projection_date(prospective_average_date)),
    y = -36,
    cex = date_cex,
    adj = 0.5,
    style = style
  )

  invisible(NULL)
}
