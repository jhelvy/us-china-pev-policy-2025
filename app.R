library(shiny)
library(plotly)

# Load preprocessed data ----
fig1 <- read.csv(
  'https://raw.githubusercontent.com/jhelvy/us-china-pev-policy-2025/refs/heads/main/data_processed/fig1-range-price.csv'
)

# Plotting parameters
colors <- list('China' = '#E41A1C', 'USA' = '#2171B5')
ylim <- 120000

# UI ----
ui <- fluidPage(
  fluidRow(
    column(
      12,
      h4("Fig. 1 with range adjustment"),
      p(
        "Different testing cycles (EPA in U.S., CLTC in China) produce different range estimates, with the CLTC tending to over-estimate range by ~30% compared to EPA. As as result, this app allows users to adjust ranges for vehicles sold in either country to better compare the BEV offerings in each country on a more equivalent basis."
      )
    ), 
    column(
      12,
      p(
        'The original (unadjusted) figure is published in: Helveston, John P. (2025) "How collaboration with China can revitalize US automotive innovation"',
        tags$i("Science"),
        ". 390(6772), pg. 446-448. ",
        tags$a(
          href = "https://doi.org/10.1126/science.adz0541",
          "DOI: 10.1126/science.adz0541"
        )
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
      plotlyOutput("range_price_plot", height = "360px", width = "900px")
    )
  ),

  hr()
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
      data$range_mi <- ifelse(
        data$country == 'China',
        data$range_mi / adjustment_factor,
        data$range_mi
      )
    } else if (input$adjust_country == "usa") {
      data$range_mi <- ifelse(
        data$country == 'USA',
        data$range_mi * adjustment_factor,
        data$range_mi
      )
    }

    return(data)
  })

  # Render plot
  output$range_price_plot <- renderPlotly({
    data <- adjusted_data()

    # Create separate plots for each class
    plot_list <- lapply(
      c("Car", "SUV", "Pickup Truck"),
      function(vehicle_class) {
        class_data <- data[data$class == vehicle_class, ]

        plot_ly(
          data = class_data,
          x = ~range_mi,
          y = ~price,
          color = ~country,
          colors = c('China' = '#E41A1C', 'USA' = '#2171B5'),
          type = 'scatter',
          mode = 'markers',
          marker = list(size = 6, opacity = 0.6),
          text = ~ paste0(
            "<b>",
            vehicle,
            "</b><br>",
            "Range: ",
            round(range_mi, 0),
            " miles<br>",
            "Price: $",
            format(price, big.mark = ",", scientific = FALSE)
          ),
          hovertemplate = '%{text}<extra></extra>',
          showlegend = FALSE
        ) %>%
          layout(
            xaxis = list(
              title = "Range (miles)",
              range = c(0, 600),
              dtick = 150
            ),
            yaxis = list(
              title = "Price ($USD)",
              range = c(0, ylim),
              dtick = 20000,
              tickformat = "$,.0f"
            ),
            annotations = list(
              list(
                text = vehicle_class,
                x = 0.5,
                y = 1.05,
                xref = "paper",
                yref = "paper",
                showarrow = FALSE,
                font = list(size = 12)
              )
            ),
            margin = list(t = 30, b = 30, l = 50, r = 5)
          )
      }
    )

    # Combine subplots
    subplot(
      plot_list,
      nrows = 1,
      shareY = TRUE,
      titleX = TRUE
    ) %>%
      layout(
        title = list(
          text = paste0(
            "Price vs. Range for all Model Year 2024 BEVs in ",
            "<span style='color:#E41A1C'>China</span> and the ",
            "<span style='color:#2171B5'>USA</span>"
          ),
          font = list(size = 12)
        ),
        showlegend = FALSE,
        margin = list(t = 50, b = 30),
        autosize = FALSE
      )
  })
}

# Run app ----
shinyApp(ui = ui, server = server)
