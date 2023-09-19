## *****************************************************************************
## # Description:
##
## Pack internal package sources using pkglite
##
## Programmer: sffl
## *****************************************************************************

# This program has been executed in 4.2.0

# Attach libraries

library(magrittr)
library(pkglite)
library(jsonlite)
library(tibble)

# Define out path for pkglite files
pkglite_path <- "~/github/phuse-css-2023/submission-files"

# Paths for renv.lock files
renv.locks <- c(
  "1234" = "~/github/css123/1234/current/stats/program/renv.lock",
  "5678" = "~/github/css123/5678/current/stats/program/renv.lock",
  "iss"  = "~/github/css123/iss/current/stats/program/renv.lock"
)

project <- "css123"

for (trial in names(renv.locks)) {
  
  cat("currently building trial", trial, "\n")
  # load the lockfile
  renv_trial <- jsonlite::read_json(renv.locks[trial])
  
  # Create text file of the internal packages
  renv_trial_data <-
    renv_trial$Packages %>%
    lapply(as.data.frame) %>%
    dplyr::bind_rows()
  
  rspm.url <- "https://rspm.bifrost-prd.corp.aws.novonordisk.com"
  repo <- "prod-internal"
  
  trial_folder <- file.path("pkglite_representation", project, trial)
  dir.create(trial_folder, showWarnings = FALSE, recursive = TRUE)
  
  tar_dir <- file.path(trial_folder, "tar_gz")
  dir.create(tar_dir, showWarnings = FALSE, recursive = TRUE)
  
  source_dir <- file.path(trial_folder, "sources")
  dir.create(source_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Find NN package versions used in trial
  for (package in grep(pattern = "^NN", renv_trial_data$Package, value = TRUE)) {
    version <- renv_trial_data[renv_trial_data$Package == package, "Version"]
    file <- paste0(package, "/", package, "_", version, ".tar.gz")
    url <- paste0(rspm.url, "/", repo, "/", "latest/src/contrib/Archive/", file)
    
    # Download tar.gz from package manager
    if (!file.exists(file.path(tar_dir, basename(file)))) {
      download.file(url, file.path(tar_dir, basename(file)))
    }
    
    untar(file.path(tar_dir, basename(file)), exdir = normalizePath(source_dir))
    
    # Remove large files primarily for internal use
    if (package == "NNBiostat") {
      unlink(file.path(source_dir, package, "README.md"))
    }
    
    if (package == "NNtraining") {
      unlink(file.path(source_dir, package, 
                       "inst/db/nn1234/nn1234-4321/current/stats/program/parprog/"), recursive = TRUE)
    }
    
    # replace non-ascii characters
    system(paste("sed -i 's/ø/oe/g' ", file.path(source_dir, package, "DESCRIPTION"))) 

    unlink(file.path(source_dir, package, "NEWS.md"))
  }
  
  
  pkgs <- list.files(source_dir, full.names = TRUE)
  file_specification <- file_default()
  
  inst <- file_spec(path = "inst/", pattern = ".*", format = "binary", all_files = TRUE)
  
  collated <- lapply(pkgs, collate, list(file_specification, inst))
  
  # Pack all package sources using pkglite::pack()
  for (i in seq_along(collated)) {
    dir.create(file.path(trial_folder, "pkglite-files"),
               showWarnings = FALSE, recursive = TRUE)
    
    pack(collated[[i]], output = 
           file.path(trial_folder, "pkglite-files", paste0(basename(pkgs)[i], ".txt")),
         quiet = TRUE)
  }
  # Verify that resulting files are ascii
  for (i in seq_along(collated)) {
    cat(paste("check ascii", basename(pkgs)[i]))
    check <- file.path(trial_folder, "pkglite-files", paste0(basename(pkgs)[i], ".txt")) %>% 
      pkglite::verify_ascii()
    print(check)
  }
  
  # If so then pack into collated file
  pkglite_file <- file.path(pkglite_path, paste0("pkglite-", trial,".txt"))
  do.call(pack, c(collated,
                  output = pkglite_file,
                  quiet = TRUE
  ))
  
  # Unpack files to check that they build
  pkglite_file %>%
    unpack(
      output = file.path(trial_folder, "pkglite_unpacked"),
      quiet = TRUE
    )
  
  pkgs <- list.files(file.path(trial_folder, "pkglite_unpacked"), full.names = TRUE)
  names(pkgs) <- sapply(pkgs, basename)
  
  pkg_cellar <- file.path(trial_folder, "cellar")
  
  # Create R tar.gz files for installation
  lapply(file.path(pkg_cellar, basename(pkgs)), dir.create, showWarnings = FALSE, recursive = TRUE)
  pkg_tar_list <- 
    mapply(devtools::build, pkgs, vignettes = FALSE, path = file.path(pkg_cellar, basename(pkgs)))

  # Check that all packages are installable
  dir.create(file.path(trial_folder, "pkglite_install"), showWarnings = FALSE, recursive = TRUE)
  install.packages(pkg_tar_list, repos = NULL, dependencies = FALSE, lib = file.path(trial_folder, "pkglite_install"))
}

