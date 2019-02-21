
library(sparklyr)
library(shiny)
library(cgdsr)
library(shinyjs)
library(DT)
library(dplyr)
library(survival)
library(survminer)
library(reshape2)
library(grid)
# Define server logic required to draw a histogram
server <- function(input, output, session) {
  
  path <- system.file(package = "shinySpark")
  r_info <- reactiveValues()
  
 # source("spark.R", encoding = "UTF-8", local = TRUE)
  source("functions.R", encoding = "UTF-8", local = TRUE)
  source("Studies.R", encoding = "UTF-8", local = TRUE)
  source("cBioPortal_ui.R", encoding = "UTF-8", local = TRUE)
  source("cBioPortal.R", encoding = "UTF-8", local = TRUE)
  source("ClinicalData_ui.R", encoding = "UTF-8", local = TRUE)
  source("ProfData.R", encoding = "UTF-8", local = TRUE)

  
  observeEvent(input$close, {
    js$closeWindow()
    stopApp()
    #spark_disconnect(r_info$sc)
  })
}

