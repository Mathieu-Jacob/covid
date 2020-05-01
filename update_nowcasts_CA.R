
# Packages -----------------------------------------------------------------
require(EpiNow)
require(NCoVUtils)
require(furrr)
require(future)
require(dplyr)
require(tidyr)
require(magrittr)
require(future.apply)
require(fable)
require(fabletools)
require(feasts)
require(urca)


# Get cases ---------------------------------------------------------------

NCoVUtils::reset_cache()

cases = get_canada_regional_cases() %>%
  dplyr::rename(region = province,
                cases = cases_confirmed)

region_codes <- cases %>%
  dplyr::select(region, region_code = pruid) %>%
  unique()

saveRDS(region_codes, "canada/data/region_codes.rds")

cases <- cases %>%
  dplyr::select(date, region, cases) %>%
  dplyr::rename(local = cases) %>%
  dplyr::mutate(imported = 0) %>%
  tidyr::gather(key = "import_status", value = "cases", local, imported)

# Get linelist ------------------------------------------------------------

linelist <- NCoVUtils::get_international_linelist()

# Set up cores -----------------------------------------------------

future::plan("multiprocess", workers = future::availableCores())

data.table::setDTthreads(threads = 1)

# Run pipeline ----------------------------------------------------

EpiNow::regional_rt_pipeline(
  cases = cases,
  linelist = linelist,
  regional_delay = FALSE,
  target_folder = "canada/regional",
  horizon = 14,
  report_forecast = TRUE,
  forecast_model = function(...) {
    EpiSoon::fable_model(model = fabletools::combination_model(fable::RW(y ~ drift()), fable::ETS(y), 
                                                               fable::NAIVE(y),
                                                               cmbn_args = list(weights = "inv_var")), ...)
  },
  samples = 10,
  verbose = TRUE
)


# Summarise results -------------------------------------------------------

EpiNow::regional_summary(results_dir = "canada/regional",
                         summary_dir = "canada/regional-summary",
                         target_date = "latest",
                         region_scale = "Province")

