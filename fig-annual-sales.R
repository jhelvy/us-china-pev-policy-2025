library(tidyverse)
library(cowplot)
options(dplyr.width = Inf)

# Plot settings

font_main <- 'Roboto Condensed'

color_icev <- "grey60" 
color_bev <- "springgreen2" 
color_phev <- "springgreen4" 

sales <- read_csv(here::here('data', 'china-sales-exports.csv')) %>% 
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
    )

sales %>% 
    filter(type %in% c('bev', 'phev', 'icev')) %>% 
    mutate(
        type = str_to_upper(type),
        type = factor(type, c('BEV', 'PHEV', 'ICEV'))
    ) %>% 
    ggplot() +
    geom_col(
        mapping = aes(x = year, y = sales, fill = type),
        alpha = 0.8, width = 0.8
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
        plot.caption.position =  "plot", 
        # legend.position = c(0.05, 0.9), 
        panel.background = element_rect(fill = "white", color = NA),
        plot.background = element_rect(fill = "white", color = NA) 
    ) +
    geom_text(
        data = sales %>% 
            filter(type == 'pev') %>% 
            mutate(label = paste(round(sales, 2), 'M')),
        mapping = aes(x = year, y = all, label = label),
        nudge_y = 0.8, hjust = 0.5,
        family = font_main
    ) + 
    geom_segment(
        data = data.frame(x = 2022, xend = 2023.4, y = 28.4, yend = 28.4),
        mapping = aes(x = x, y = y, xend = xend, yend = yend),
        arrow = arrow(20, unit(0.1, "inches"), "last", "closed"),
        alpha = 1, inherit.aes = FALSE
    ) +
    annotate( 
        x = 2021.2, y = 28.4, geom = 'text',
        label = 'Total PEV sales',
        family = font_main
    )


ggsave(
    here::here('figs', 'annual-sales.png'),
    width = 8, height = 6
)
