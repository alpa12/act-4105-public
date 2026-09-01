test_that("year methods use the French abbreviations", {
  expect_identical(
    vapply(
      c("calendar", "accident", "policy", "reporting"),
      tarifr:::year_method_prefix,
      character(1)
    ),
    c(calendar = "AC", accident = "AA", policy = "AP", reporting = "AR")
  )
})

test_that("diagram default labels use the French abbreviations", {
  expect_identical(
    tarifr:::default_period_label("2024-01-01", "calendar"),
    "AC 2024"
  )
  expect_identical(
    tarifr:::default_period_label("2024-01-01", "accident"),
    "AA 2024"
  )
  expect_identical(
    tarifr:::default_period_label("2024-01-01", "policy"),
    "AP 2024"
  )
})
