## *****************************************************************************
## # Description: 
##
## Build study containers and setup renv in each study
## Unpacks the internally developed in Novo Nordisk packages and prepares
## for download of externally needed packages.
##
## Programmer: sffl+aikp+abiu
## *****************************************************************************

# Define necessary paths

# Define path for pkg lite files
pkglite_path <- "to-be-shared"   # UPDATE TO YOUR PATH

# Define path to the unwrapped source code
pkglite_source <- "pkglite_source" 

# Define path to the build tar.gz files that will be used when evaluating code
pkglite_cellar <- "pkglite_cellar"

# Define path to root renv folder structure
renv_root <- "~/renv-root"

# project_root
project_root <- pkglite_path

project <- "css123"

# Paths to public package managers with compiled binaries available
public_pkg_urls <- c("https://packagemanager.posit.co/cran/2021-06-09",
                     "https://packagemanager.posit.co/cran/2021-09-29")

## *****************************************************************************
## # install/load required packages                                         ----
## *****************************************************************************

# Install required libraries if they are not present 

# Ensure installation of CRAN packages in the versions used in submission
rspm_repo = public_pkg_urls[1]
if (!requireNamespace("pkglite", quietly = TRUE)) 
  install.packages("pkglite", repos = rspm_repo)
if (!requireNamespace("devtools", quietly = TRUE)) 
  install.packages("devtools", repos = rspm_repo)
if (!requireNamespace("usethis", quietly = TRUE)) 
  install.packages("usethis", repos = rspm_repo)
if (!requireNamespace("jsonlite", quietly = TRUE)) 
  install.packages("jsonlite", repos = rspm_repo)

# Attach libraries
library(pkglite)
library(devtools)
library(usethis)
library(jsonlite)

## *****************************************************************************
## # Unpack pkglite files                                                   ----
##
## The pkglite representation of the internal packages used in the different
## Parts of the submission are unpackaged and build as tar.gz files
## *****************************************************************************

pkglite_files <- list.files(pkglite_path, pattern = "^pkglite-.*\\.txt")
for (pkglite_file in pkglite_files) {
  
  # Make sure a folder exist for the unpacked source files
  cat("unpacking", pkglite_file, "\n")
  pkglite_output <- file.path(pkglite_source, tools::file_path_sans_ext(pkglite_file))
  dir.create(pkglite_output, showWarnings = FALSE, recursive = TRUE)
  
  # Unpack the pkglite representation
  unpack(file.path(pkglite_path, pkglite_file),
         output = pkglite_output,
         quiet = TRUE
  )
  
  # Get the names of the packages used
  pkgs <- list.files(pkglite_output, full.names = TRUE)
  names(pkgs) <- sapply(pkgs, basename)
  
  # Create R tar.gz files for installation
  lapply(file.path(pkglite_cellar, basename(pkgs)), dir.create, showWarnings = FALSE, recursive = TRUE)
  pkg_tar_list <-
    mapply(devtools::build, pkgs, vignettes = FALSE, path = file.path(pkglite_cellar, basename(pkgs)))
}

## *****************************************************************************
## # Create folders capable of bootstrapping                                ----
##
## Each study in the submission is run within slightly different environments.
## This part of the script creates folders capable of bootstrapping each study.
## *****************************************************************************

# Define the .Renviron file
renviron_content <- c(
  paste0("RENV_PATHS_ROOT='", normalizePath(renv_root),"'"),
  paste0("RENV_PATHS_LOCAL='", normalizePath(pkglite_cellar),"'"),
  paste0("RENV_CONFIG_MRAN_ENABLED = FALSE")
)

# Add Rtools 4.0 if on windows
if (.Platform$OS.type == "windows") {
  write('PATH="${RTOOLS40_HOME}\\usr\\bin;${PATH}"', file = "~/.Renviron", append = TRUE)
  rtools <- 'PATH="${RTOOLS40_HOME}\\usr\\bin;${PATH}"'
} else {
  rtools <- ""
}

# Get the trial names
trials_01 <- list.files(pkglite_path, pattern = "^pkglite-.*\\.txt")
trials <- gsub(".txt$", "", gsub("^pkglite-", "", trials_01))

for (trial in trials) {
  
  # Create folders
  new_trial_folder <- file.path(project_root, project, trial, "custom/stats/program")
  dir.create(file.path(new_trial_folder, "renv"), showWarnings = FALSE, recursive = TRUE)
  dir.create(file.path(new_trial_folder, "statprog"), showWarnings = FALSE, recursive = TRUE)
  writeLines("Place the .R scripts in here", file.path(new_trial_folder, "statprog/README"))
  
  # Create some convience folders and helper README files
  dir.create(file.path(new_trial_folder,  "../data/sdtm"), showWarnings = FALSE, recursive = TRUE)
  writeLines("Place your SDTM in this folder", file.path(new_trial_folder, "../data/sdtm/README"))
  dir.create(file.path(new_trial_folder,  "../data/adam"), showWarnings = FALSE, recursive = TRUE)
  writeLines("Place your ADAM in this folder", file.path(new_trial_folder, "../data/adam/README"))
  dir.create(file.path(new_trial_folder,  "../data/metadata"), showWarnings = FALSE, recursive = TRUE)
  writeLines("Place your metadata in this folder", file.path(new_trial_folder, "../data/metadata/README"))
  dir.create(file.path(new_trial_folder,  "../output/output_datasets"), showWarnings = FALSE, recursive = TRUE)
  writeLines("The outputs will appear here", file.path(new_trial_folder, "../output/README"))
  
  # Create needed files for renv
  writeLines(renviron_content, file.path(new_trial_folder, ".Renviron"))
  writeLines('source("renv/activate.R")', file.path(new_trial_folder, ".Rprofile"))
  file.copy(file.path(pkglite_path, "activate.txt"), 
            file.path(new_trial_folder, "renv", "activate.R"))
  file.copy(file.path(pkglite_path, paste0("renvlock-", trial, ".txt")), 
            file.path(new_trial_folder, "renv.lock"))
  

  # Create R project file
  create_project(new_trial_folder, open = FALSE)
  unlink(file.path(new_trial_folder, "R"))
  
  # Create lib calls to all R packages:
  lock_contents <- readLines(file.path(new_trial_folder, "renv.lock"))
  package_lines <- grep('"Package":', lock_contents, value = TRUE)
  packages <- gsub('\",?', "", gsub('.*: *\"', "", package_lines))
  
  writeLines(paste0("library(", packages, ")"), 
             file.path(new_trial_folder, "_dependecies.R"))
  
  # Update renv.lock to use compiled binaries from a public package manager
  lock_json <- jsonlite::fromJSON(paste(lock_contents, collapse = "\n"))
  lock_json$R$Repositories <- rbind(lock_json$R$Repositories,lock_json$R$Repositories)
  lock_json$R$Repositories$URL <- public_pkg_urls
  
  # On windows some packages need an updated compiled binary
  if (!is.null(lock_json$Packages$Rcpp$Version))
    lock_json$Packages$Rcpp$Version <- "1.0.7"
  if (!is.null(lock_json$Packages$sp$Version))
    lock_json$Packages$sp$Version <- "1.4-5"
  if (!is.null(lock_json$Packages$xfun$Version))
    lock_json$Packages$xfun$Version <- "0.23"
  if (!is.null(lock_json$Packages$rmarkdown$Version))
    lock_json$Packages$rmarkdown$Version <- "2.8"
  lock_return <- jsonlite::toJSON(lock_json, pretty = TRUE, auto_unbox = TRUE)
  writeLines(lock_return, con = file.path(new_trial_folder, "renv.lock"))
}



