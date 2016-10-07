rm(list=ls())

library(tidyverse)

ultrasound <- read_csv("input_data/training_ultrasound.csv")

# SUBJID is unique across STUDYID
# DELIVERY subcategory only available for STUDYID == 2
# PARITY >= 1 for STUDYID == 1, inconsistent with STUDYID == 2

ultrasound <- ultrasound %>%
              mutate(
                  STUDYID = as.factor(STUDYID),
                  SUBJID = as.factor(SUBJID),
                  SEX = recode_factor(SEX, "Male"="M", "Female"="F"),
                  DELIVERY = as.factor(as.integer(substr(DELIVERY, 10, 10))),
                  PARITY = PARITY - as.integer(STUDYID == 1)
              ) %>%
              arrange(SUBJID, GAGEDAYS)

children <- ultrasound %>%
            select(STUDYID:GRAVIDA, BHC_Z:BHC_40) %>%
            group_by(SUBJID) %>%
            slice(1) %>%
            ungroup() %>%
            transmute(
                study_id = STUDYID,
                subject_id = SUBJID,
                sex = SEX,
                delivery = DELIVERY,
                parity = PARITY,
                pregnancies = GRAVIDA,
                birth_gage = GAGEBRTH,
                birth_wt = BIRTHWT / 1000,
                birth_len = BIRTHLEN,
                birth_hc = BIRTHHC,
                ft_wt = BWT_40,
                ft_len = BLEN_40,
                ft_hc = BHC_40,
                ft_wt_z = BWT_Z,
                ft_len_z = BLEN_Z,
                ft_hc_z = BHC_Z
            )

scans <- ultrasound %>%
         filter(AGEDAYS < 0) %>%
         transmute(
             subject_id = SUBJID,
             gage = GAGEDAYS,
             age = AGEDAYS,
             ac = ABCIRCM,
             bpd = BPDCM,
             femur = FEMURCM,
             hc = HCIRCM,
             ac_z = ACAZ,
             bpd_z = BPDAZ,
             femur_z = FLAZ,
             hc_z = HCAZ
         )

postnatal <- ultrasound %>%
             filter(AGEDAYS > 0) %>%
             transmute(
                 subject_id = SUBJID,
                 gage = GAGEDAYS,
                 age = AGEDAYS,
                 wt = WTKG,
                 len = LENCM,
                 bmi = BMI,
                 hc = HCIRCM,
                 wt_z = WAZ,
                 len_z = HAZ,
                 bmi_z = BAZ,
                 wt_len_z = WHZ,
                 hc_z = HCAZ
             )

rm(ultrasound)

