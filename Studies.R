
output$StudiesTable <- DT::renderDataTable({
  shiny::withProgress(message = 'loading Studies from cgdsr server...', value = 1, {

  displayTable(Studies)
  })

})
