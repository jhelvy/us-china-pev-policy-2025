library(shiny)
library(plotly)
library(DT)

# Load preprocessed data ----
fig1 <- read.csv(
  'https://raw.githubusercontent.com/jhelvy/us-china-pev-policy-2025/refs/heads/main/data_processed/fig1-range-price.csv'
)
fig1$price <- round(fig1$price, 0)

# Plotting parameters
colors <- list('China' = '#E41A1C', 'USA' = '#2171B5')
ylim <- 120000

# UI ----
ui <- fluidPage(
  titlePanel("Fig. 1 with range adjustment"),

  fluidRow(
    column(
      12,
      p(
        'Different testing cycles (EPA in U.S., CLTC in China) produce different range estimates, with the CLTC tending to over-estimate range by ~30% compared to EPA. This app allows users to adjust the BEV ranges to better compare the BEV offerings in each country on a more equivalent basis by either', tags$i("decreasing"), 'the Chinese ranges or', tags$i("increasing"), 'the U.S. ranges by a user-specified percentage (default 30%).'
      ),
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

  hr(),

  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("Controls"),

      radioButtons(
        "adjust_country",
        "Adjust ranges for:",
        choices = c(
          "No adjustment" = "none",
          "EPA (reduces China ranges)" = "china",
          "CLTC (increases USA ranges)" = "usa"
        ),
        selected = "none"
      ),
      sliderInput(
        "adjustment_percent",
        "Adjustment percentage:",
        min = 0,
        max = 50,
        value = 30,
        step = 1,
        post = "%"
      ),

      hr(),

      radioButtons(
        "price_filter_type",
        "Price filter:",
        choices = c("Below" = "below", "Above" = "above"),
        selected = "below",
        inline = TRUE
      ),
      sliderInput(
        "price_filter",
        "Price threshold ($):",
        min = 0,
        max = 120000,
        value = 120000,
        step = 5000,
        pre = "$"
      ),

      hr(),

      radioButtons(
        "range_filter_type",
        "Range filter:",
        choices = c("Below" = "below", "Above" = "above"),
        selected = "below",
        inline = TRUE
      ),
      sliderInput(
        "range_filter",
        "Range threshold (miles):",
        min = 0,
        max = 600,
        value = 600,
        step = 10
      )
    ),

    mainPanel(
      width = 9,
      tabsetPanel(
        tabPanel(
          "Visualization",
          br(),
          h4("Summary of Filtered BEVs with Adjusted Ranges"),
          tableOutput("summary_table"),
          hr(),
          plotlyOutput("range_price_plot", height = "320px", width = "100%")
        ),
        tabPanel(
          "Data",
          br(),
          downloadButton("download_data", "Download Data as CSV"),
          br(),
          br(),
          DTOutput("data_table")
        )
      )
    )
  )
)

# Server ----
server <- function(input, output) {
  # Reactive data with adjustments and filters
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

    # Apply price filter
    if (input$price_filter_type == "below") {
      data <- data[data$price <= input$price_filter, ]
    } else {
      data <- data[data$price >= input$price_filter, ]
    }

    # Apply range filter
    if (input$range_filter_type == "below") {
      data <- data[data$range_mi <= input$range_filter, ]
    } else {
      data <- data[data$range_mi >= input$range_filter, ]
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
        height = 320,
        width = 900,
        autosize = FALSE
      )
  })

  # Render summary table
  output$summary_table <- renderTable({
    data <- adjusted_data()

    # Calculate summary by country
    summary <- data.frame(
      Country = c("China", "USA"),
      `Number of\nVehicles` = c(
        sum(data$country == "China"),
        sum(data$country == "USA")
      ),
      `Mean Price\n($)` = c(
        mean(data$price[data$country == "China"], na.rm = TRUE),
        mean(data$price[data$country == "USA"], na.rm = TRUE)
      ),
      `Median Price\n($)` = c(
        median(data$price[data$country == "China"], na.rm = TRUE),
        median(data$price[data$country == "USA"], na.rm = TRUE)
      ),
      `Mean Range\n(miles)` = c(
        mean(data$range_mi[data$country == "China"], na.rm = TRUE),
        mean(data$range_mi[data$country == "USA"], na.rm = TRUE)
      ),
      `Median Range\n(miles)` = c(
        median(data$range_mi[data$country == "China"], na.rm = TRUE),
        median(data$range_mi[data$country == "USA"], na.rm = TRUE)
      ),
      check.names = FALSE
    )

    # Format the table
    summary$`Mean Price\n($)` <- paste0("$", format(round(summary$`Mean Price\n($)`, 0), big.mark = ","))
    summary$`Median Price\n($)` <- paste0("$", format(round(summary$`Median Price\n($)`, 0), big.mark = ","))
    summary$`Mean Range\n(miles)` <- format(round(summary$`Mean Range\n(miles)`, 0), nsmall = 0)
    summary$`Median Range\n(miles)` <- format(round(summary$`Median Range\n(miles)`, 0), nsmall = 0)

    return(summary)
  }, striped = TRUE, hover = TRUE, bordered = TRUE)

  # Render full data table
  output$data_table <- renderDT({
    data <- adjusted_data()

    # Format the data for display
    display_data <- data.frame(
      Vehicle = data$vehicle,
      Make = data$make,
      Model = data$model,
      Year = data$model_year,
      Country = data$country,
      Class = data$class,
      Powertrain = data$powertrain,
      `Range (miles)` = round(data$range_mi, 1),
      `Price ($)` = round(data$price, 0),
      check.names = FALSE
    )

    datatable(
      display_data,
      options = list(
        pageLength = 25,
        order = list(list(8, 'desc')), # Sort by Range (miles) descending by default
        columnDefs = list(
          list(className = 'dt-center', targets = c(3, 4, 5, 6, 7, 8)) # Center align certain columns
        )
      ),
      rownames = FALSE,
      filter = 'top'
    ) %>%
      formatCurrency('Price ($)', currency = "$", interval = 3, mark = ",", digits = 0)
  })

  # Download handler
  output$download_data <- downloadHandler(
    filename = function() {
      paste0("bev_data_", Sys.Date(), ".csv")
    },
    content = function(file) {
      data <- adjusted_data()

      # Prepare data for export
      export_data <- data.frame(
        vehicle = data$vehicle,
        make = data$make,
        model = data$model,
        model_year = data$model_year,
        country = data$country,
        class = data$class,
        powertrain = data$powertrain,
        range_mi = round(data$range_mi, 1),
        price = round(data$price, 0)
      )

      write.csv(export_data, file, row.names = FALSE)
    }
  )
}

# Run app ----
shinyApp(ui = ui, server = server)
