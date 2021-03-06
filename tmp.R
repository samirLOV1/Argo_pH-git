---
  title: "Dyfamed cruise before and during deployement of Argo float lovapm016a and lovapm016b"
author: "Jean-Pierre Gattuso, Samir Alliouane and Hervé Claustre"
date: "`r format(Sys.Date(), '%d %B, %Y')`"
output: html_document
---
  
  
  ```{r set-up, echo=FALSE, warning=FALSE, message=FALSE, results='hide'}
Sys.setlocale("LC_ALL", "en_US.UTF-8")
rm(list = ls())
## theme to format the plots
Sys.setenv(TZ='UTC') 
# on utilise UTC
library(tidyverse)
library(seacarb) 
library(lubridate)
library(knitr)
library(ncdf4)
library(curl)
library(RColorBrewer)
library(scales)

#define who is the user and define path
if (Sys.getenv("LOGNAME") == "gattuso") path = "../../pCloud\ Sync/Documents/experiments/exp174_Argo_pH/"
if (Sys.getenv("LOGNAME") == "samir") path = "../../pCloud\ Sync/exp174_Argo_pH/"

#################### which.closest function
which.closest <- function(x, table, ...) {
  round(approx(x=table, y=1:length(table), xout=x, ...)$y)
}

```

# Introduction
This document presents results of pH measurements obtained during MOOSE cruises:
  
  - 113 on 8 November 2017. Samples have been collected at the Dyfamed station by Emilie Diamond and Melek Golbol.
- 114 on 4 December 2017. Samples have been collected at the Dyfamed station by Eduardo Soto and Emilie Diamond.
- 120 on 30 June 2018. Samples have been collected at the Dyfamed station by Eduardo Soto and Emilie Diamond.
- 130 on 2019-04-16. Samples have been collected at the Dyfamed by Eduardo Soto and Melek Golbol.


**Floats:**
  
- MOOSE 113 and 114: lovapm016a
- MOOSE 120: lovapm016b
- MOOSE 130: lovapm016c


#Materiel and Methods
Samples were collected in 500 ml borosilicated glass bottles, poisoned, and stored pending analysis. pH was measured using the spectrophotometric method (Dickson et al., 2007) with purified m-cresol purple (purchased from Robert H. Byrne’s laboratory, University of South Florida for 113 and 114 cruises and obtained from Fluidion society, France for 120 cruise). pH measurements were performed at room temperature by Samir Alliouane on 9 November 2017, 26 December 2017 on the Ocean Optics spectrophotometer (cruises 113 and 114) and on 4 July 2018 on Cary60 spectrophotometer (cruise 120). pH values are on the total scale and are expressed at in situ temperature and pressure using the function pHinsi of the R package seacarb 3.2.3 (Gattuso et al., 2017). A tentative total alkalinity of 2560 uEq/kg was used. This will need to be changed to values obtained by SNAPO-CO2. 

- Total alkalinity was measured on 24 November 2017 for the sample collected at 1000 m during cruise 113: TA = 2581.77 uEq/kg (n=2, SD=0.68 uEq/kg). Theoretical CRM value is 2213.59 uEq/kg (Batch 159) and measured CRM was 2213.19 uEq/kg.
- Total alkalinity was measured on 15 March 2018 for the sample at 1000 m during cruise 114: TA = 2592.73 uEq/kg (n=3, SD=1.41 uEq/kg). Theoretical CRM value is 2217.4 uEq/kg (Batch 171) and measured CRM was 2211.5 uEq/kg.
- Total alkalinity was measured on 20 July 2018 for samples at 1000 m and 2000 m during cruise 120: TA was respectively 2582.90 uEq/kg (n=2, SD=0.30 uEq/kg) and 2582.16 uEq/kg (n=2, SD=1.27 uEq/kg). Theoretical CRM value is 2226.16 uEq/kg (Batch 145) and measured CRM was 2222.67 uEq/kg (n=2, SD=0.88 uEq/kg).
- Total alkalinity was measured on 18 April 2019 for samples at 1000 m and surface m during cruise 130: TA was respectively 2586.43 uEq/kg (n=2, SD=0.43 uEq/kg) and 2576.07 uEq/kg (n=2, SD=0.57 uEq/kg). Theoretical CRM value is 2213.59 uEq/kg (Batch 159) and measured CRM was 2216.10 uEq/kg (n=2, SD=0.10 uEq/kg).


#Results

##MOOSE 113 and 114

```{r read data, echo=FALSE, message=FALSE, out.width='100%'}
floats <- c("lovapm016a", "lovapm016b", "lovapm016c")
for (f in 1:length(floats)) {
  float <- floats[f]
  if (file.exists(paste0(path, "./data/", float, ".rds")) == TRUE) {
    readRDS(paste0(path, "data/", float, ".rds"))
    tmp <- get(floats[f])
  } else {
    if (exists("tmp") == TRUE) rm(tmp) # delete tmp of previous float
  }
  files <- curl(paste0("http://poteau:poteau@www.oao.obs-vlfr.fr/BD_FLOAT/NETCDF/", float, "/liste_all"), open="r")
  fil <- readLines(files)
  for (i in 1:length(fil)){
    loc_file_name <-  str_extract(fil[[i]], "out(.+)nc")
    loc_file_path <-  paste0(path, "./data/argo_archive/", loc_file_name)
    rem_file_name <- paste0("http://poteau:poteau@www.oao.obs-vlfr.fr/BD_FLOAT/NETCDF/", float, "/", loc_file_name)
    
    if (file.exists(paste0(path, "./data/argo_archive/", loc_file_name)) == FALSE){
      print(loc_file_name)
      curl_download(url = rem_file_name, destfile = loc_file_path)
      filenc <- nc_open(loc_file_path, readunlim=FALSE, write=FALSE)
      # YYYYMMDDHHMISS
      REFERENCE_DATE_TIME <- ncvar_get(filenc, "REFERENCE_DATE_TIME")
      JULD <- ncvar_get(filenc, "JULD")
      TIME <- ncvar_get(filenc, "TIME")
      adatetime <- ymd_hms(as.numeric(REFERENCE_DATE_TIME)) +
        days(as.integer(TIME)) + (TIME - as.integer(TIME)) * 24 * 60 * 60
      aTinsitu <- ncvar_get(filenc,"TEMP")
      aSal <- ncvar_get(filenc,"PSAL")
      aProf <- ncvar_get(filenc,"PRES")
      apH <- ncvar_get(filenc, "PH_IN_SITU_TOTAL")
      adata <- tibble(adatetime, aTinsitu, aSal, aProf, apH)
      if (exists("tmp") == FALSE) {
        tmp <- adata
      } else {
        tmp <- bind_rows(tmp, adata)
      }
      dplyr::distinct(tmp) %>% # remove duplicates if any
        dplyr::arrange(adatetime) # re-order
      
      assign(x = floats[f], tmp)
      saveRDS(get(floats[f]), file = paste0(path, "./data/", floats[f], ".rds"))
    }
  }
}
```

```{r combine floats data, echo=FALSE, message=FALSE, out.width='100%'}
floats <- c("lovapm016a", "lovapm016b", "lovapm016c")
dat <- NULL
for (f in 1:length(floats)) {
  tmp <- get(x = floats[f]) %>%
    dplyr::mutate(float = floats[f])
  dat <- dat %>% 
    dplyr::bind_rows(tmp)# %>%
  #dplyr::rename(Prof = aProf)
}
```


```{r merge lab data, echo=FALSE, message=FALSE, out.width='100%'}
# read and organize
d <- read_delim(paste0(path, "./data/Dyfamed.csv"), col_names=TRUE, delim = ";")
d$date <- dmy(d$date)  
d$date_analysis <- dmy(d$date_analysis) 
d$Niskin <- as.numeric(d$Niskin) 

# join lab and field dataframes
dat2 <- full_join(dat, d, by = c("aProf" = "Prof"))

#PROBLEME les profoneurs ne correspondent pas. Utiliser la fonction which.closest comme dans awipev-co2

# # TA interpolation
# m120 <- d%>%
#   dplyr::filter(Cruise == "Moose120")
# atinterp <-approx(m120$Niskin, m120$ta, xout=m120$Niskin, method="linear", rule=2)
# names(atinterp) <- c("date", "ta")
# atinterp <- as.data.frame(atinterp)
# m120$ta <- atinterp$ta
# 
# m130 <- d%>%
#   dplyr::filter(Cruise == "Moose130")
# atinterp <-approx(m130$Niskin, m130$ta, xout=m130$Niskin, method="linear", rule=2)
# names(atinterp) <- c("date", "ta")
# atinterp <- as.data.frame(atinterp)
# m130$ta <- atinterp$ta
# 
# dd <- d%>%
#   dplyr::mutate(ta = )
d <- d %>%
  dplyr::mutate(pHspec_Tinsitu = pHinsi(pH=d$pHlab,ALK=d$ta*1e-6, Tinsi=d$Tinsitu, Tlab=d$Tlab, Pinsi= d$Prof/10, S=d$Sal,Pt=0,Sit=0))

#data <- full_join(d, adata, by = c("Prof" = "aProf"))
data <- d %>% 
  dplyr::group_by(Cruise, Niskin) %>% 
  dplyr::summarize(Depth = mean(Prof, na.rm = T),
                   Sal = mean(Sal, na.rm = T),
                   ta = mean(ta, na.rm = T),
                   Tlab = mean(Tlab, na.rm = T),
                   Tinsitu = mean(Tinsitu, na.rm = T),
                   pHlab = mean(pHlab, na.rm = T),
                   pH_Tinsitu = mean(pHspec_Tinsitu, na.rm = T), 
                   sd = sd(pHspec_Tinsitu, na.rm = T)
  )
data <- data %>%
  dplyr::arrange(Cruise, Depth)

kable(data, align = 'c', col.names = c("Cruise", "Niskin Bottle", "Depth", "Salinity","TA" ,"lab T", "in situ T", "lab pHT", "in situ pHT","sd"), digits = 4)
```

```{r fig pH S T, echo=FALSE, warning= FALSE,out.width='100%'}
data_long <- data %>%
  dplyr::select(Cruise, Depth, Sal, Tinsitu, pH_Tinsitu) %>%
  gather(key="variable", value="value", -Cruise, -Depth)

# To change labels in facet_wrap()
labels <- c(Sal = "Salinity",
            Tinsitu="T in situ",
            pH_Tinsitu= "pH in situ")

### Plot sal and temp ###
data_long %>% 
  ggplot(aes(y = Depth, x = value, color=factor(Cruise))) + 
  labs(y = "Depth (m)",
       x = "PSU, °C and pH units",
       color = "") +
  geom_point(size= 1) + 
  geom_path() +
  facet_wrap(~variable, nrow = 1, scales = "free_x", 
             labeller = labeller(variable=labels)) +
  scale_y_reverse() +
  theme(legend.position='top')
```

## MOOSE 113 and 114

```{r fig Argo MOOSE 113 and 114, echo=FALSE, warning= FALSE, fig.width=6,fig.height=8}
d <- lovapm016a %>%
  dplyr::mutate(adate = as_date(adatetime)) %>%
  dplyr::filter(!is.na(apH) & apH < 9 & adate > "2017-12-03")
cols_blues <- colorRampPalette(brewer.pal(9,"Blues"))(length(unique(d$adate)))
d %>%
  ggplot(aes(y = aProf, x = apH)) +
  geom_point(aes(color = factor(adate)), size = 0.2) +
  scale_color_manual(values = cols_blues,
                     na.value = "gray90",
                     name = NULL,
                     guide = "legend",
                     labels = unique(d$adate),
                     drop = FALSE) +
  #  scale_x_discrete(position = "top") +
  scale_y_reverse() +
  labs(y = "Depth (m)",
       x = "pH units",
       color = "") +
  theme(legend.position='top')
```

```{r pH around 1000 m, echo=FALSE, warning= FALSE,out.width='100%'}
#pHspec_Tinsitu at 1000 m
pH_1000 <- ungroup(data) %>%
  filter(as.integer(Depth) == 1000) %>%
  select(pH_Tinsitu)
d <- lovapm016a %>%
  dplyr::mutate(adate = as_date(adatetime)) %>%
  dplyr::filter(!is.na(apH) & apH < 9 & adate > "2017-12-03" & aProf < 1020 & aProf >980)
d %>%
  ggplot(aes(y = apH, x = adatetime)) +
  geom_point(color = "blue", size = 1) +
  geom_hline(yintercept = pH_1000[[1]], color="blue", linetype="dashed") +
  labs(y = "pH",
       x = "Time",
       title = "pH between 980 and 1020 m, dashed lines show spec pH at 1000 m") +
  scale_x_datetime(breaks = date_breaks("1 week"), labels = date_format("%d %b")) +
  theme(legend.position="bottom", axis.text.x = element_text(angle = 45, hjust = 1)) 
```   

```{r range, echo=FALSE, warning= FALSE,out.width='100%'}
d <- lovapm016a %>%
  dplyr::filter(!is.na(apH) & apH < 9) %>%
  dplyr::mutate(adate = as_date(adatetime)) %>%
  dplyr::group_by(adate) %>%
  dplyr::mutate(range = max(apH) - min(apH)) %>%
  dplyr::filter(adate > "2017-12-03")
d %>%
  ggplot(aes(y = range, x = adatetime)) +
  geom_point(color = "blue", size = 1) +
  labs(y = "pH",
       x = "Time",
       title = "pH range (max - min)") +
  scale_x_datetime(breaks = date_breaks("1 week"), labels = date_format("%d %b")) +
  theme(legend.position="bottom", axis.text.x = element_text(angle = 45, hjust = 1)) 
```   




In the figure below, the depth distribution of pHT is shown. The error bars are standard deviations of 3 or 4 replicate measurements performed on the same sampling bottle.

```{r Graph2, echo=FALSE, warning= FALSE,out.width='100%'}
### Plot pH with error bars ###
d <- filter(data, Cruise=="Moose114") # discrete
ad <- lovapm016a %>% #Argo
  dplyr::mutate(adate = as_date(adatetime)) %>%
  dplyr::filter(!is.na(apH) & apH < 9 & (adate == "2017-12-04" | adate == "2017-12-05"))
ggplot() + 
  labs(y = "Depth (m)",
       x = "pH units",
       color = "") +
  geom_point(data = d, 
             aes(y = Depth, x = pH_Tinsitu, color="Moose114"), size= 1) +
  geom_path(data = d, aes(y = Depth, x = pH_Tinsitu, color="Moose114")) +
  geom_errorbarh(data = d, 
                 aes(y = Depth, x = pH_Tinsitu, xmin = pH_Tinsitu - sd,
                     xmax = pH_Tinsitu + sd, color="Moose114"),
                 height=2, size=0.5) +
  scale_y_reverse() +
  #Now Argo
  geom_point(data = ad, 
             aes(y = aProf, x = apH, color="Argo"), size= 1) +
  theme(legend.position='top')
```

##MOOSE 120

```{r fig Argo MOOSE 120, echo=FALSE, warning= FALSE, fig.width=6,fig.height=8}
d <- lovapm016b %>%
  dplyr::mutate(adate = as_date(adatetime)) %>%
  dplyr::filter(!is.na(apH) & apH < 9 & adate > "2017-12-03")
cols_blues <- colorRampPalette(brewer.pal(9,"Blues"))(length(unique(d$adate)))
d %>%
  ggplot(aes(y = aProf, x = apH)) +
  geom_point(aes(color = factor(adate)), size = 0.2) +
  scale_color_manual(values = cols_blues,
                     na.value = "gray90",
                     name = NULL,
                     guide = "legend",
                     labels = unique(d$adate),
                     drop = FALSE) +
  #  scale_x_discrete(position = "top") +
  scale_y_reverse() +
  labs(y = "Depth (m)",
       x = "pH units",
       color = "") +
  theme(legend.position='top')
```

```{r pH around 1000 m MOOSE 120, echo=FALSE, warning= FALSE,out.width='100%'}
#pHspec_Tinsitu at 1000 m
pH_1000 <- ungroup(data) %>%
  filter(as.integer(Depth) == 1000) %>%
  select(pH_Tinsitu)
d <- lovapm016b %>%
  dplyr::mutate(adate = as_date(adatetime)) %>%
  dplyr::filter(!is.na(apH) & apH < 9 & adate > "2017-12-03" & aProf < 1020 & aProf >980)
d %>%
  ggplot(aes(y = apH, x = adatetime)) +
  geom_point(color = "blue", size = 1) +
  geom_hline(yintercept = pH_1000[[1]], color="blue", linetype="dashed") +
  labs(y = "pH",
       x = "Time",
       title = "pH between 980 and 1020 m, dashed lines show spec pH at 1000 m") +
  scale_x_datetime(breaks = date_breaks("1 week"), labels = date_format("%d %b")) +
  theme(legend.position="bottom", axis.text.x = element_text(angle = 45, hjust = 1)) 
```   

```{r range MOOSE 120, echo=FALSE, warning= FALSE,out.width='100%'}
d <- lovapm016b %>%
  dplyr::filter(!is.na(apH) & apH < 9) %>%
  dplyr::mutate(adate = as_date(adatetime)) %>%
  dplyr::group_by(adate) %>%
  dplyr::mutate(range = max(apH) - min(apH)) %>%
  dplyr::filter(adate > "2017-12-03")
d %>%
  ggplot(aes(y = range, x = adatetime)) +
  geom_point(color = "blue", size = 1) +
  labs(y = "pH",
       x = "Time",
       title = "pH range (max - min)") +
  scale_x_datetime(breaks = date_breaks("1 week"), labels = date_format("%d %b")) +
  theme(legend.position="bottom", axis.text.x = element_text(angle = 45, hjust = 1)) 
```   



In the figure below, the depth distribution of pHT is shown. The error bars are standard deviations of 3 or 4 replicate measurements performed on the same sampling bottle.

```{r Graph2 MOOSE 120, echo=FALSE, warning= FALSE,out.width='100%'}
### Plot pH with error bars ###
d <- filter(data, Cruise=="Moose114") # discrete
ad <- lovapm016b %>% #Argo
  dplyr::mutate(adate = as_date(adatetime)) #%>%
#dplyr::filter(!is.na(apH) & apH < 9 & (adate == "2017-12-04" | adate == "2017-12-05"))
ggplot() + 
  labs(y = "Depth (m)",
       x = "pH units",
       color = "") +
  geom_point(data = d, 
             aes(y = Depth, x = pH_Tinsitu, color="Moose120"), size= 1) +
  geom_path(data = d, aes(y = Depth, x = pH_Tinsitu, color="Moose120")) +
  geom_errorbarh(data = d, 
                 aes(y = Depth, x = pH_Tinsitu, xmin = pH_Tinsitu - sd,
                     xmax = pH_Tinsitu + sd, color="Moose120"),
                 height=2, size=0.5) +
  scale_y_reverse() +
  #Now Argo
  geom_point(data = ad, 
             aes(y = aProf, x = apH, color="Argo"), size= 1) +
  theme(legend.position='top')
```

#Acknowledgements
Thanks are due to Laurent Coppola, Emilie Diamond, Melek Golbol, Edouard Leymarie, Antoine Poteau and Catherine Schmechtig for assistance in the field and in the laboratory.

#References
Dickson A. G., Sabine C. L. & Christian J. R., 2007. Guide to best practices for ocean CO2 measurements. PICES Special Publication 3:1-191.

Gattuso J.-P., Epitalon J.-M., Lavigne H. & Orr J., 2017. seacarb: seawater carbonate chemistry. R package version 3.2.3. [https://cran. r-project.org/package=seacarb](cran. r-project.org/package=seacarb).