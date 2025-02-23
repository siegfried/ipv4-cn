file <- "https://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest"

fetch_data <- function() {
  readr::read_delim(
    file,
    delim = "|",
    comment = "#",
    col_names = c(
      "owner", "region", "type", "address", "number", "summary", "unknown"
    ),
    col_types = "ccccicccc"
  )
}

calculate_cidr <- function(number) {
  floor(32 - log2(number))
}

filter_ipv4_cn <- function(data) {
  data |>
    dplyr::filter(region == "CN" & type == "ipv4") |>
    dplyr::transmute(
      address,
      number,
      cidr_prefix = calculate_cidr(number),
      prefixed_address = paste(address, cidr_prefix, sep = "/")
    )
}

save_ipv4_cn <- function(data, file) {
  data |>
    filter_ipv4_cn() |>
    dplyr::select(prefixed_address) |>
    readr::write_csv(file, col_names = FALSE)
}
