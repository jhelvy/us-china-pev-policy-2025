library(tidyverse)
library(cowplot)
options(dplyr.width = Inf)

# Plot settings

font_main <- 'Roboto Condensed'

color_icev <- "grey60"
color_bev <- "springgreen2"
color_phev <- "springgreen4"

fig2 <- read_csv(here::here('data', 'china-sales-exports.csv')) %>%
    filter(!is.na(sales)) %>%
    filter(type != 'nev') %>%
    select(year, type, sales) %>%
    pivot_wider(names_from = type, values_from = sales) %>%
    mutate(
        pev = bev + phev,
        icev = all - pev,
        percent_pev = pev / all
    ) %>%
    pivot_longer(
        names_to = 'type',
        values_to = 'sales',
        cols = bev:icev
    ) %>%
    filter(type %in% c('bev', 'phev', 'icev')) %>%
    mutate(
        type = str_to_upper(type),
        type = factor(type, c('BEV', 'PHEV', 'ICEV'))
    )

# Save formatted plot data
write_csv(fig2, here::here('data_processed', 'fig2-annual-sales.csv'))

fig2 %>%
    ggplot() +
    geom_col(
        mapping = aes(x = year, y = sales, fill = type),
        alpha = 0.8,
        width = 0.8
    ) +
    scale_fill_manual(values = c(color_bev, color_phev, color_icev)) +
    scale_x_continuous(breaks = seq(2016, 2024)) +
    scale_y_continuous(
        breaks = c(10, 20, 30),
        limits = c(0, 30),
        expand = expansion(mult = c(0, 0.05)),
    ) +
    labs(
        fill = 'Powertrain',
        x = NULL,
        y = 'Annual Vehicle Sales (Millions)',
        title = "In China, PEV sales grow while ICEV sales slow",
        subtitle = "After peaking in 2017, internal combustion engine vehicle (ICEV) sales have declined for 7 straight years",
        caption = 'Data sources: marklines.com'
    ) +
    theme_minimal_hgrid(font_family = font_main) +
    theme(
        plot.caption = element_text(hjust = 0, face = "italic"),
        plot.title.position = "plot",
        plot.caption.position = "plot",
        legend.position = "none",
        panel.background = element_rect(fill = "white", color = NA),
        plot.background = element_rect(fill = "white", color = NA)
    ) +
    # Add text in last bar
    geom_text(
        data = sales %>%
            filter(year == 2024) %>%
            filter(type != 'pev') %>%
            arrange(factor(type, levels = c("icev", "phev", "bev"))) %>%
            mutate(
                # Calculate cumulative sums for positioning
                ymax = cumsum(sales),
                ymin = lag(ymax, default = 0),
                # Position labels in the middle of each segment
                y_pos = (ymin + ymax) / 2,
                label = str_to_upper(type)
            ),
        mapping = aes(x = year, y = y_pos, label = label),
        color = c('white', 'white', 'black'),
        family = font_main,
        fontface = "bold"
    ) +
    # Add PEV sales above bars
    geom_text(
        data = sales %>%
            filter(type == 'pev') %>%
            mutate(label = paste(round(sales, 2), 'M')),
        mapping = aes(x = year, y = all, label = label),
        nudge_y = 0.8,
        hjust = 0.5,
        family = font_main
    ) +
    geom_segment(
        data = data.frame(x = 2022, xend = 2023.4, y = 28.4, yend = 28.4),
        mapping = aes(x = x, y = y, xend = xend, yend = yend),
        arrow = arrow(20, unit(0.1, "inches"), "last", "closed"),
        alpha = 1,
        inherit.aes = FALSE
    ) +
    annotate(
        x = 2021.2,
        y = 28.4,
        geom = 'text',
        label = 'Total PEV sales',
        family = font_main
    )

ggsave(
    here::here('figs', 'fig2-annual-sales.png'),
    width = 7,
    height = 6
)

ggsave(
    here::here('figs', 'fig2-annual-sales.pdf'),
    width = 7.5,
    height = 6,
    device = cairo_pdf
)
