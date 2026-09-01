# Install the local tarifr package used by the Quarto site.

.find_repo_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)

  repeat {
    package_desc <- file.path(current, "tarifr", "DESCRIPTION")
    git_dir <- file.path(current, ".git")

    if (file.exists(package_desc) && (dir.exists(git_dir) || file.exists(git_dir))) {
      return(current)
    }

    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Impossible de trouver la racine du depot contenant le package local 'tarifr'.", call. = FALSE)
    }

    current <- parent
  }
}

install_tarifr <- function(path = NULL,
                           lib = .libPaths()[1],
                           dependencies = NA,
                           upgrade = FALSE,
                           ask = interactive(),
                           quiet = FALSE) {
  package_dir <- if (is.null(path)) {
    file.path(.find_repo_root(), "tarifr")
  } else {
    path
  }

  package_dir <- normalizePath(package_dir, winslash = "/", mustWork = TRUE)

  if (!file.exists(file.path(package_dir, "DESCRIPTION"))) {
    stop("Le chemin fourni ne pointe pas vers un package R valide: ", package_dir, call. = FALSE)
  }

  if (requireNamespace("pak", quietly = TRUE)) {
    pak::local_install(
      root = package_dir,
      lib = lib,
      upgrade = upgrade,
      ask = ask,
      dependencies = dependencies
    )
  } else if (requireNamespace("devtools", quietly = TRUE)) {
    devtools::install(
      pkg = package_dir,
      reload = FALSE,
      quiet = quiet,
      dependencies = dependencies,
      upgrade = upgrade
    )
  } else {
    utils::install.packages(
      pkgs = package_dir,
      lib = lib,
      repos = NULL,
      type = "source",
      dependencies = dependencies,
      quiet = quiet
    )
  }

  invisible(package_dir)
}

install_tarifr()
