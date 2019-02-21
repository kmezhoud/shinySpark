# library(survival)
# library(survminer)
# library(cgdsr)
# library(sparklyr)
# library(dplyr)
# 
# 
# cgds <- cgdsr::CGDS("http://www.cbioportal.org/")
# #Studies<- cgdsr::getCancerStudies(cgds)
# clinicalData <- cgdsr::getClinicalData(cgds, "gbm_tcga_pub_all")
# 
# #clinicalData <- read.csv("Clinical_tab.csv") #, na.strings=c("","NA")
# 
# clinicalData$OS_STATUS <- gsub("LIVING", "0", clinicalData$OS_STATUS, ignore.case = TRUE)
# clinicalData$OS_STATUS <- gsub("DECEASED", "1", clinicalData$OS_STATUS, ignore.case = TRUE)
# clinicalData$DFS_STATUS <- gsub("^$|^ $", "DiseaseFree", clinicalData$DFS_STATUS, ignore.case = TRUE)
# clinicalData$OS_STATUS <- as.numeric(clinicalData$OS_STATUS)
# fit <- survival::survfit(Surv(OS_MONTHS, OS_STATUS) ~ DFS_STATUS, data = clinicalData)
# ##### ggplot
#   clinicalData %>% 
#   arrange(OS_MONTHS) %>%
#   mutate(DiseaseFree = ifelse(DFS_STATUS == "DiseaseFree", 1, 0)) %>%
#   mutate(n_DiseaseFree = cumsum(DiseaseFree == 1)) %>%
#   mutate(n_Recurred = cumsum(DiseaseFree == 0)) %>%
#   ggplot(aes(x = OS_MONTHS, y = value, color = variable)) +
#   geom_point(aes(y = n_DiseaseFree, col = "n_DiseaseFree")) +
#   geom_point(aes(y = n_Recurred, col = "n_Recurred")) 
# 
# ### spark node staff
# sc <- spark_connect(master = "local")
# 
# clinicalData_tbl <- dplyr::copy_to(sc, clinicalData, overwrite = TRUE)
# 
#   clinicalData_tbl %>%
#   mutate(OS_STATUS = regexp_replace(OS_STATUS, "LIVING", "0")) %>%
#   mutate(OS_STATUS = regexp_replace(OS_STATUS, "DECEASED", "1")) %>%
#   mutate(DFS_STATUS = regexp_replace(DFS_STATUS, "^$|^ $", "DiseaseFree")) %>%
#   mutate(OS_STATUS = as.numeric(OS_STATUS)) %>%
#   arrange(OS_MONTHS) %>%
#   mutate( DiseaseFree = ifelse(DFS_STATUS == "DiseaseFree", 1, 0)) %>% 
#   as.data.frame() %>%
#   mutate( n_DiseaseFree = cumsum(DiseaseFree == 1 )) %>%
#   mutate( n_Recurred = cumsum(DiseaseFree == 0 )) %>%
#   ggplot(aes(x = OS_MONTHS, y = value, color = variable)) +
#   geom_point(aes(y = n_DiseaseFree, col = "n_DiseaseFree")) +
#   geom_point(aes(y = n_Recurred, col = "n_Recurred")) 
#   #ml_aft_survival_regression(OS_MONTHS ~ DFS_STATUS + SEX , censor_col = "OS_STATUS")
# 
# # spark_apply(function(df) {
# #   library(survival)
# #   survival::survfit(Surv(OS_MONTHS, OS_STATUS) ~ DFS_STATUS, data = df)
# # })
# 
# 
# ####
# 
# ### replace empty by na
# 
# #clinicalData <- read.csv("Clinical_tab.csv", na.strings=c("","NA"))
# #apply(clinicalData, 2, function(x) gsub("^$|^ $", NA, x)) %>% head()
# #clinicalData %>% dplyr::mutate_all(funs(empty_as_na)) %>% head()
# clinicalData %>% tidyr::replace_na() %>% head()
# 
# ## working
# #clinicalData_tbl %>% spark_apply(function(df) df[['OS_MONTHS']] * 10) %>% head()
# 
# ## from spark node
# clinicalData_tbl <- clinicalData_tbl %>%  tidyr::replace_na()
# #clinicalData_tbl <- dplyr::mutate(clinicalData_tbl, DFS_STATUS = regexp_replace(DFS_STATUS, "^$|^ $", "NA"))
# clinicalData_tbl <- dplyr::mutate(clinicalData_tbl, DFS_STATUS = regexp_replace(DFS_STATUS, "^$|^ $", "DiseaseFree"))
# 
# 
# ## filter row by column
# #clinicalData_tbl %>% filter(rlike(DFS_STATUS, "DiseaseFree"))
# 
# # works
# fit_tbl <- ml_aft_survival_regression(x = clinicalData_tbl, OS_MONTHS ~ DFS_STATUS , censor_col = "OS_STATUS")
# 
# fit_tbl <-
#   clinicalData_tbl %>%
#   spark_apply(function(df) {
#   library(survival)
#   survival::survfit(Surv(OS_MONTHS, OS_STATUS) ~ DFS_STATUS, data = df)
# })
#   
# fit_tbl <- spark_apply(
#   clinicalData_tbl,
#   function(e) broom::tidy(lm(OS_MONTHS ~ OS_STATUS, e)),
#   names = c("term", "estimate", "std.error", "statistic", "p.value"),
#   group_by = "DFS_STATUS",
#   packages = FALSE)
# 
# survminer::ggsurvplot(fit_tbl, data = clinicalData,
#                       type = "kaplan-meier",
#                       #conf.type="log",
#                       conf.int = TRUE,
#                       pval = TRUE,
#                       fun = "pct",
#                       risk.table = TRUE,
#                       size = 1,
#                       linetype = "strata",
#                       palette = c("#E7B800", "#2E9FDF"),
#                       legend = "top",
#                       lengend.title = "DFS_STATUS",
#                       legend.labs = c("DiseaseFree", "Recurred")
# )
# 
# 
# 
# # sc %>% spark_session() %>% invoke("table", "clinicaldata") %>%
# #   mutate(DFS_STATUS=regexp_replace(DFS_STATUS, "^$|^ $", "NA"))
# #   sdf_register("mutated")
# 
# 
# if(length(grep("^OS_STATUS$", names(clinicalData), ignore.case = TRUE))  == 1   &&   
#    length(grep("^OS_MONTHS$", names(clinicalData), ignore.case = TRUE))  == 1   &&
#    length(grep("^DFS_STATUS$", names(clinicalData), ignore.case = TRUE)) == 1
# ){
#   
#   
#   clinicalData$OS_STATUS <- gsub("LIVING", "0", clinicalData$OS_STATUS)
#   clinicalData$OS_STATUS <- gsub("DECEASED", "1", clinicalData$OS_STATUS)
#   clinicalData$OS_STATUS <- as.numeric(clinicalData$OS_STATUS)
#   
#   fit <- survival::survfit(Surv(OS_MONTHS, OS_STATUS) ~ DFS_STATUS ,data = clinicalData)
#   
#   survminer::ggsurvplot(fit, data = clinicalData,
#                         type = "kaplan-meier",
#                         #conf.type="log",
#                         conf.int = TRUE,
#                         pval = TRUE,
#                         fun = "pct",
#                         risk.table = TRUE,
#                         size = 1,
#                         linetype = "strata",
#                         palette = c("#E7B800", "#2E9FDF"),
#                         legend = "top",
#                         lengend.title = "DFS_STATUS",
#                         legend.labs = c("DiseaseFree", "Recurred")
#   )
#   
# }else{
#   msgNoData <- "There is no \n OS_STATUT or OS_MONTHS or DFS_STATUS data"
#   #stop(msgNoData)
#   break(msgNoData)
# }
# 
# 
# 
# 
