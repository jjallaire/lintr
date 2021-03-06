#' Clear the lintr cache
#'
#' @param file filename whose cache to clear.  If you pass \code{NULL} it will
#' delete all of the caches.
#' @param path directory to store caches.  Reads option 'lintr.cache_directory'
#' as the default.
#' @export
clear_cache <- function(file, path = getOption("lintr.cache_directory")) {
  if (is.null(file)) {
    unlink(path, recursive = TRUE)
  }
  else {
    file <- basename(file)
    unlink(file.path(path, file))
  }
}

load_cache <- function(file, path = getOption("lintr.cache_directory")) {
  file <- basename(file)
  env <- new.env(parent=emptyenv())

  file_path <- file.path(path, file)
  if (file.exists(file_path)) {
    load(file = file.path(path, file), envir = env)
  }
  env
}

save_cache <- function(cache, file, path = getOption("lintr.cache_directory")) {
  file <- basename(file)
  if (!file.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
  save(file = file.path(path, file), envir = cache, list=ls(envir=cache))
}

cache_lint <- function(cache, expr, linter, lints) {
  assign(
    envir = cache,
    x = digest::digest(list(linter, expr$content), algo="sha1"),
    value = lints)
}

retrieve_lint <- function(cache, expr, linter, lines) {
  lints <- get(
    envir = cache,
    x = digest::digest(list(linter, expr$content), algo="sha1"),
  )
  lints[] <- lapply(lints, function(lint) {
    lint$line_number <- find_new_line(lint$line_number, unname(lint$line), lines)
    lint
  })
  cache_lint(cache, expr, linter, lints)
  lints
}

has_lint <- function(cache, expr, linter) {
  exists(envir = cache,
    x = digest::digest(list(linter, expr$content), algo="sha1"),
    )
}

find_new_line <- function(line_number, line, lines) {

  if (lines[line_number] %==% line) {
    return(line_number)
  }

  width <- 1L

  while(width <= length(lines)) {
    low <- line_number - width
    if (low > 0L) {
      if (lines[low] %==% line) {
        return(low)
      }
    }
    high <- line_number + width
    if (high <= length(lines)) {
      if (lines[high] %==% line) {
        return(high)
      }
    }
    width <- width + 1L
  }
  return(NA)
}
