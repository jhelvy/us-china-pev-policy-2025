library(tidyverse)
library(cowplot)
library(arrow)
library(ggtext)
library(ggrepel)

# Conversions

km_per_mi <- 1.6
dollars_per_rmb <- 0.14

# China cleaning ----

dt_china <- read_parquet(file.path('data', 'car_specs_china.parquet'))

dt_china <- dt_china %>%
  mutate(
    model_year = parse_number(model_year),
    range_km = case_when(
      is.na(range_km) ~ range_km_cltc,
      is.na(range_km_cltc) ~ range_km_nedc,
      is.na(range_km_nedc) ~ range_km_wltc,
      is.na(range_km_wltc) ~ range_km_tested,
      is.na(range_km_tested) ~ range_km_miit,
      is.na(range_km_miit) ~ range_km_nedc_comprehensive,
      is.na(range_km_nedc_comprehensive) ~ range_km_wltc_comprehensive
    ),
    range_mi = range_km / km_per_mi,
    msrp = msrp * dollars_per_rmb, # convert to dollars
    price = price / 1000 # convert to thousands
  ) %>%
  select(
    price, # in 1000 dollars
    msrp,
    brand,
    series,
    model,
    manufacturer,
    class,
    model_year,
    fuel_type,
    range_mi,
    class
  ) %>%
  filter(model_year < 2025) %>%
  filter(!is.na(range_mi)) %>%
  filter(!is.na(price)) %>%
  filter(!is.na(model_year)) %>%
  filter(!is.na(fuel_type)) %>%
  mutate(
    class = case_when(
      str_detect(class, 'Car') ~ 'Car',
      str_detect(class, 'SUV') ~ 'SUV',
      str_detect(class, 'Pickup Truck') ~ 'Pickup Truck',
      TRUE ~ "other"
    )
  ) %>%
  filter(class != 'other')
dt_china$class <- factor(dt_china$class, c('Car', 'SUV', 'Pickup Truck'))

# Top-range BEV
dt_china %>%
  arrange(desc(range_mi)) %>%
  slice(1:5) %>%
  select(brand, model, model_year, price, range_mi)

# Models above 500 miles range
dt_china %>%
  filter(model_year == 2024) %>%
  filter(range_mi > 400) %>%
  arrange(desc(range_mi)) %>%
  select(brand, series, model_year, price, range_mi)

# Take mean price and range across each series
dt_china <- dt_china %>%
  group_by(model_year, brand, series, class, fuel_type) %>%
  summarise(
    price = mean(price),
    range_mi = mean(range_mi)
  ) %>%
  ungroup() %>%
  rename(model = series, powertrain = fuel_type)

# Find target models by name for labeling

dt_china %>%
  filter(model_year == 2024) %>%
  filter(brand == 'BYD') %>%
  # filter(manufacturer == 'Tesla') %>%
  # filter(manufacturer == 'MI') %>%
  count(model)

dt_china <- dt_china %>%
  mutate(
    target_model = model %in%
      c(
        "SongL EV",
        "Song Plus",
        "SU7",
        "Model Y"
      ),
    # Change MI to Xiaomi
    brand = ifelse(brand == 'MI', 'Xiaomi', brand),
    vehicle = paste(brand, model)
  )

# USA cleaning ----

dt_us <- read_parquet(file.path('data', 'car_specs_us.parquet'))

dt_us <- dt_us %>%
  select(
    make,
    model,
    model_year = year,
    trim,
    price = msrp,
    drivetrain,
    fuel_type,
    range_mi,
    body_style,
    electric_range_mi,
    powertrain
  ) %>%
  mutate(
    range_mi = ifelse(
      is.na(electric_range_mi),
      range_mi,
      electric_range_mi
    ),
    price = price / 1000, # convert to thousands
    powertrain = str_to_upper(powertrain),
    # Add range for missing vehicles
    range_mi = ifelse(model == "Cybertruck", 350, range_mi),
    range_mi = ifelse(trim == "Cyberbeast", 320, range_mi)
  ) %>%
  filter(model_year < 2025, model_year > 2019) %>%
  filter(powertrain %in% c('BEV', 'PHEV')) %>%
  mutate(
    class = case_when(
      body_style %in%
        c('Convertible', "Couple", "Hatchback", "Sedan", "Wagon") ~
        'Car',
      str_detect(body_style, 'SUV') ~ 'SUV',
      str_detect(body_style, 'Pickup Truck') ~ 'Pickup Truck',
      TRUE ~ "other"
    )
  ) %>%
  filter(class != 'other')

dt_us$class <- factor(dt_us$class, c('Car', 'SUV', 'Pickup Truck'))

# Top-range BEV
dt_us %>%
  arrange(desc(range_mi)) %>%
  slice(1:10) %>%
  select(make, model, model_year, price, range_mi)

# Models above 500 miles range
dt_us %>%
  filter(range_mi > 500) %>%
  arrange(desc(range_mi)) %>%
  select(make, model, model_year, price, range_mi)

# Take mean price and range across each series
dt_us <- dt_us %>%
  group_by(model_year, make, model, class, powertrain) %>%
  summarise(
    price = mean(price),
    range_mi = mean(range_mi)
  ) %>%
  ungroup() %>%
  mutate(
    range_mi = ifelse(model == "Equinox EV", 319, range_mi),
    range_mi = ifelse(model == "Model Y", 291, range_mi),
    range_mi = ifelse(model == "Model 3", 332, range_mi),
    range_mi = ifelse(model == "Macan", 352, range_mi),
    range_mi = ifelse(model == "Wagoneer S", 294, range_mi),
    range_mi = ifelse(model == "Mustang Mach-E", 270, range_mi),
    range_mi = ifelse(model == "500e", 141, range_mi),
    range_mi = ifelse(model == "Ocean", 231, range_mi)
  )

# Find target models by name for labeling

dt_us %>%
  filter(model_year == 2024) %>%
  # filter(make == 'Nissan') %>%
  filter(make == 'Tesla') %>%
  # filter(make == 'Chevrolet') %>%
  # filter(make == 'Polestar') %>%
  count(model) %>%
  as.data.frame()

dt_us <- dt_us %>%
  mutate(
    target_model = model %in%
      c(
        "LEAF",
        "Model Y",
        "Model 3",
        "Equinox EV",
        "2",
        "e-tron GT",
        "Cybertruck",
        "F-150 Lightning"
      ),
    vehicle = paste(make, model)
  )

# Combined data ----

dt_combined <- dt_us %>%
  mutate(country = 'USA') %>%
  select(
    vehicle,
    model,
    model_year,
    range_mi,
    price,
    powertrain,
    country,
    class,
    target_model
  ) %>%
  rbind(
    dt_china %>%
      mutate(country = 'China') %>%
      select(
        vehicle,
        model,
        model_year,
        range_mi,
        price,
        powertrain,
        country,
        class,
        target_model
      )
  )

# US-China 2024 ----

colors <- list('China' = '#E41A1C', 'USA' = '#2171B5')
font_main <- 'Roboto Condensed'
ylim <- 120000

dt_combined %>%
  filter(powertrain == 'BEV') %>%
  filter(model_year == 2024) %>%
  mutate(price = price * 1000) %>%
  ggplot() +
  geom_point(
    aes(
      x = range_mi,
      y = price,
      color = country
    ),
    size = 0.8,
    alpha = 0.6
  ) +
  # Add manual text labels for countries
  # annotate("text", x = 190, y = 85000, label = "USA", color = colors$USA, fontface = "bold", size = 5, family = font_main) +
  # annotate("text", x = 500, y = 16000, label = "China", color = colors$China, fontface = "bold", size = 5, family = font_main) +
  theme_minimal_grid(font_family = font_main) +
  scale_y_continuous(
    breaks = seq(0, ylim, 20000),
    labels = scales::dollar
  ) +
  scale_x_continuous(
    breaks = seq(0, 600, 150)
  ) +
  coord_cartesian(
    xlim = c(0, 600),
    ylim = c(0, ylim)
  ) +
  scale_color_manual(values = c(unlist(colors))) +
  labs(
    x = 'Range (miles)',
    y = 'Price ($USD)',
    title = "Price vs. Range for all Model Year 2024 BEVs in <span style='color:#E41A1C'>China</span> & the <span style='color:#2171B5'>USA</span>",
    subtitle = "China offers more affordable BEVs with higher ranges"
  ) +
  theme(
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.title = element_markdown(family = font_main),
    legend.position = 'none',
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    strip.background = element_rect(fill = "gray", color = NA)
  ) +
  panel_border()


# US-China 2024 by Class ----

fig1 <- dt_combined %>%
  # filter(country == 'USA') %>%  # Turn on for USA only version
  filter(powertrain == 'BEV') %>%
  filter(model_year == 2024) %>%
  mutate(price = price * 1000)

# Save formatted plot data
write_csv(fig1, here::here('data_processed', 'fig1-range-price.csv'))

plot <- fig1 %>%
  ggplot() +
  geom_point(
    aes(
      x = range_mi,
      y = price,
      color = country
    ),
    size = 0.8,
    alpha = 0.6
  ) +
  facet_wrap(vars(class), nrow = 1) +
  theme_minimal_grid(font_family = font_main) +
  scale_y_continuous(
    breaks = seq(0, ylim, 20000),
    labels = scales::dollar
  ) +
  scale_x_continuous(
    breaks = seq(0, 600, 150)
  ) +
  coord_cartesian(
    xlim = c(0, 600),
    ylim = c(0, ylim)
  ) +
  scale_color_manual(values = c(unlist(colors))) +
  labs(
    x = 'Range (miles)',
    y = 'Price ($USD)',
    title = "Price vs. Range for all Model Year 2024 BEVs in <span style='color:#E41A1C'>China</span> and the <span style='color:#2171B5'>USA</span>",
    subtitle = "China offers more affordable options across all range categories"
  ) +
  theme(
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.title = element_markdown(family = font_main),
    legend.position = 'none',
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    strip.background = element_rect(fill = "gray", color = NA)
  ) +
  panel_border()

plot

# Add labels

plot +
  geom_text_repel(
    data = fig1 %>%
      mutate(vehicle = ifelse(target_model, vehicle, '')),
    aes(
      x = range_mi,
      y = price,
      color = country,
      label = vehicle
    ),
    # Add these parameters to improve label placement
    size = 3.5,
    family = font_main,
    force = 50, # Increase repulsion force
    box.padding = 1, # Padding around labels
    segment.color = "grey50", # Color of connector lines
    min.segment.length = 0, # Show all connector lines
    max.overlaps = Inf, # Don't discard any labels
    seed = 9 # For reproducible results
  )

ggsave(
  file.path('figs', 'fig1-range-price.png'),
  width = 11,
  height = 4.5,
  dpi = 300
)

ggsave(
  file.path('figs', 'fig1-range-price.pdf'),
  width = 11,
  height = 4.5,
  device = cairo_pdf
)

# Version with 30% range reduction for Chinese BEVs

dt_adjusted <- dt_combined %>%
  filter(powertrain == 'BEV') %>%
  filter(model_year == 2024) %>%
  mutate(
    price = price * 1000,
    range_mi = ifelse(country == 'China', range_mi * 0.7, range_mi)
  )

dt_adjusted %>%
  ggplot() +
  geom_point(
    aes(
      x = range_mi,
      y = price,
      color = country
    ),
    size = 0.8,
    alpha = 0.6
  ) +
  facet_wrap(vars(class), nrow = 1) +
  theme_minimal_grid(font_family = font_main) +
  scale_y_continuous(
    breaks = seq(0, ylim, 20000),
    labels = scales::dollar
  ) +
  scale_x_continuous(
    breaks = seq(0, 600, 150)
  ) +
  coord_cartesian(
    xlim = c(0, 600),
    ylim = c(0, ylim)
  ) +
  scale_color_manual(values = c(unlist(colors))) +
  labs(
    x = 'Range (miles)',
    y = 'Price ($USD)',
    title = "Price vs. Range for all Model Year 2024 BEVs in <span style='color:#E41A1C'>China</span> and the <span style='color:#2171B5'>USA</span>",
    subtitle = "China offers more affordable options across all range categories"
  ) +
  theme(
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.title = element_markdown(family = font_main),
    legend.position = 'none',
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    strip.background = element_rect(fill = "gray", color = NA)
  ) +
  panel_border() +
  geom_text_repel(
    data = dt_adjusted %>%
      mutate(vehicle = ifelse(target_model, vehicle, '')),
    aes(
      x = range_mi,
      y = price,
      color = country,
      label = vehicle
    ),
    # Add these parameters to improve label placement
    size = 3.5,
    family = font_main,
    force = 50, # Increase repulsion force
    box.padding = 1, # Padding around labels
    segment.color = "grey50", # Color of connector lines
    min.segment.length = 0, # Show all connector lines
    max.overlaps = Inf, # Don't discard any labels
    seed = 9 # For reproducible results
  )

ggsave(
  file.path('figs', 'fig1-range-price-adjusted.png'),
  width = 11,
  height = 4.5,
  dpi = 300
)
