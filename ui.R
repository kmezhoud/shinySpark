jscode <- "shinyjs.closeWindow = function() { window.close(); }"
# Define UI for application that draws a histogram
ui <- fluidPage(
 
  useShinyjs(),
  extendShinyjs(text = jscode, functions = c("closeWindow")),
  
  # Application title
  titlePanel("Manage Spark cluster by shiny"),
  
  uiOutput("cBioPortal")
)