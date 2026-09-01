year_method_prefix <- function(year_method) {
  switch(
    year_method,
    calendar = "AC",
    accident = "AA",
    policy = "AP",
    reporting = "AR"
  )
}
