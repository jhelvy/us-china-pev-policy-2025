library(shiny)
library(tidyverse)
library(cowplot)
library(ggtext)
library(ggrepel)

# Load preprocessed data ----
fig1 <- read_csv('data_processed/fig1-range-price.csv', show_col_types = FALSE)

# Plotting parameters
colors <- list('China' = '#E41A1C', 'USA' = '#2171B5')
font_main <- 'sans'
ylim <- 120000

# UI ----
ui <- fluidPage(
  titlePanel("Interactive Figure 1: BEV Price vs. Range (2024)"),

  fluidRow(
    column(
      12,
      h4("Range Adjustment"),
      p(
        "Different testing cycles (EPA in US, CLTC in China) produce different range estimates.
        CLTC tends to over-estimate range by ~30% compared to EPA."
      )
    )
  ),

  fluidRow(
    column(
      4,
      radioButtons(
        "adjust_country",
        "Adjust ranges for:",
        choices = c(
          "No adjustment" = "none",
          "EPA (reduces China ranges)" = "china",
          "CLTC (increases USA ranges)" = "usa"
        ),
        selected = "none"
      )
    ),
    column(
      8,
      sliderInput(
        "adjustment_percent",
        "Adjustment percentage:",
        min = 0,
        max = 50,
        value = 30,
        step = 1,
        post = "%"
      )
    )
  ),

  hr(),

  fluidRow(
    column(
      12,
      plotOutput("range_price_plot", height = "360px", width = "880px")
    )
  ),

  hr(),

  fluidRow(
    column(
      12,
      p("Data source: Helveston (2025) Science 390(6772)"),
      p(tags$a(
        href = "https://doi.org/10.1126/science.adz0541",
        "DOI: 10.1126/science.adz0541"
      ))
    )
  )
)

# Server ----
server <- function(input, output) {
  # Reactive data with adjustments
  adjusted_data <- reactive({
    data <- fig1

    # Convert percentage to factor (0-50% -> 1.0-1.5)
    adjustment_factor <- 1 + (input$adjustment_percent / 100)

    # Apply adjustment based on selection
    if (input$adjust_country == "china") {
      data <- data %>%
        mutate(
          range_mi = ifelse(
            country == 'China',
            range_mi / adjustment_factor,
            range_mi
          )
        )
    } else if (input$adjust_country == "usa") {
      data <- data %>%
        mutate(
          range_mi = ifelse(
            country == 'USA',
            range_mi * adjustment_factor,
            range_mi
          )
        )
    }

    return(data)
  })

  # Create subtitle based on adjustment
  plot_subtitle <- reactive({
    if (input$adjust_country == "none") {
      return("China offers more affordable options across all range categories")
    } else if (input$adjust_country == "china") {
      return(paste0(
        "China ranges reduced by ",
        input$adjustment_percent,
        "% to approximate EPA testing cycle"
      ))
    } else {
      return(paste0(
        "USA ranges increased by ",
        input$adjustment_percent,
        "% to approximate CLTC testing cycle"
      ))
    }
  })

  # Render plot
  output$range_price_plot <- renderPlot({
    data <- adjusted_data()

    plot <- data %>%
      ggplot() +
      geom_point(
        aes(
          x = range_mi,
          y = price,
          color = country
        ),
        size = 1.5,
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
        subtitle = plot_subtitle()
      ) +
      theme(
        plot.title.position = "plot",
        plot.caption.position = "plot",
        plot.title = element_markdown(family = font_main, size = 16),
        plot.subtitle = element_text(size = 12),
        legend.position = 'none',
        panel.background = element_rect(fill = "white", color = NA),
        plot.background = element_rect(fill = "white", color = NA),
        strip.background = element_rect(fill = "gray", color = NA),
        strip.text = element_text(size = 12),
        axis.title = element_text(size = 12),
        axis.text = element_text(size = 10)
      ) +
      panel_border() +
      geom_text_repel(
        data = data %>%
          mutate(vehicle = ifelse(target_model, vehicle, '')),
        aes(
          x = range_mi,
          y = price,
          color = country,
          label = vehicle
        ),
        size = 3,
        family = font_main,
        force = 50,
        box.padding = 1,
        segment.color = "grey50",
        min.segment.length = 0,
        max.overlaps = Inf,
        seed = 9
      )

    print(plot)
  })
}

# Run app ----
shinyApp(ui = ui, server = server)
