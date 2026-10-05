# Installs the development version of incidenceinflation into a project-local
# library (.lib/), leaving any other installed version untouched.
package_path <- Sys.getenv("INCIDENCEINFLATION_PATH", "../incidenceinflation_2.0")
dir.create(".lib", showWarnings = FALSE)
install.packages(package_path, repos = NULL, type = "source", lib = ".lib")
