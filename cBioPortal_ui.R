output$cBioPortal <- renderUI({
  # tagList(
  sidebarLayout(
    sidebarPanel(
      actionButton("connect", "Connect to spark", style="color: #0447FF"),
      
      #wellPanel(
      #conditionalPanel("input.tabs_cbioportal == 'Studies'",
      #                uiOutput("Welcome"),
      #                 uiOutput("ui_Studies")),
      #conditionalPanel("input.tabs_cbioportal != 'Studies'",
      selectizeInput(
        'StudiesID', 'Select a study', choices = Studies, selected = "gbm_tcga_pub" ,multiple = FALSE
      ),
      uiOutput("ui_Cases"),
      conditionalPanel("input.tabs_cbioportal != 'Clinical'",
                       uiOutput("ui_GenProfs")
                       
                       
      ),
      # ),
      
      conditionalPanel("input.tabs_cbioportal == 'Clinical'", 
                       uiOutput("ui_ClinicalData")
      ),
      #conditionalPanel("input.tabs_cbioportal == 'ProfData'", uiOutput("ui_ProfData")),
      #conditionalPanel("input.tabs_cbioportal == 'Mutation'", uiOutput("ui_MutData"))
      
      #)
      actionButton("close", "Close window & disconnect", style = "color: #FF0404")
    ),
    mainPanel(
      # conditionalPanel("input.overview_id == true",
      #                  uiOutput("pipeline"),
      #                  imageOutput("overview")
      # ),
      
      # tags$hr(),
      
      tabsetPanel(id = "tabs_cbioportal",
                  
                  tabPanel("Studies",
                           #downloadLink("dl_Studies_tab", "", class = "fa fa-download alignright"),
                           DT::dataTableOutput(outputId = "StudiesTable")
                  ),
                  tabPanel("Clinical",
                           #downloadLink("dl_Clinical_tab", "", class = "fa fa-download alignright"),
                           DT::dataTableOutput(outputId="ClinicalDataTable"),
                           #if(!is.null(input$SurvPlotID)){ #!is.null(input$clinicalDataButtID) && 
                           
                           div(class="row",
                               div(class="col-xs-6",
                                   conditionalPanel("input.SurvPlotID ==true",
                                                    h5("survival Plot from R session"),
                                                    plotOutput("suvivalPlot")
                                   )
                                   
                               ),
                               div(class="col-xs-6"
                                   
                               )
                           ),
                           div(class= "row",
                            div(class="col-xs-6",
                                   conditionalPanel("input.SurvPlotID == true",
                                                    h5("R session plot"),
                                                    plotOutput("clinicalDataPlot")
                                   )
                                 
                               ),
                               div(class="col-xs-6",
                                   conditionalPanel("input.SurvPlotID ==true &&
                                                    input.clinicalDataButtID == true",
                                                    h5("spark transformation and plot"),
                                                    plotOutput("clinicalDataPlot_spark")
                                   )
                               )
                               
                           )
                           
                  ),
                  tabPanel("ProfData",
                           #downloadLink("dl_ProfData_tab", "", class = "fa fa-download alignright"),
                           DT::dataTableOutput(outputId ="ProfDataTable")
                           
                  ),
                  tabPanel("Mutation",
                           DT::dataTableOutput(outputId ="MutDataTable")
                  )
      )
    )
  )
  # )
})
