
source("load.R")

children <- children %>%
            select(study_id:pregnancies, ft_wt) %>%
            filter(!is.na(ft_wt)) %>%
            mutate(
                parity_cat = factor(replace(parity, parity > 3, 3),
                                    0:3, c(0:2, "3+")),
                first_pregnancy = (pregnancies == 1)
            )

scans <- scans %>%
         select(subject_id:hc) %>%
         filter(complete.cases(.)) %>%
         group_by(subject_id) %>%
         arrange(gage) %>%
         mutate_at(vars(ac:hc),
                   funs(changed = (row_number(.) == 1) | (. - lag(.) != 0))) %>%
         filter(ac_changed | bpd_changed | femur_changed | hc_changed) %>%
         select(-ends_with("_changed")) %>%
         ungroup() %>%
         group_by(subject_id) %>%
         arrange(gage) %>%
         filter(age <= -7*4) %>%  # Remove scans > 4 weeks before delivery
         slice(max(1, n()-2):n()) %>%  # Keep only last 3 scans
         mutate(scan_no = 1:n()) %>%
         mutate_at(vars(ac:hc),
                   funs(
                       square = (.)^2,
                       cube = (.)^3,
                       diff = (lag(.) - .),
                       delta = (lag(.) - .) / (lag(gage) - gage)
                   )) %>%
         mutate_at(vars(bpd, femur, hc),
                   funs(ac_ratio = . / ac)) %>%
         mutate_at(vars(ac, femur, hc),
                   funs(bpd_ratio = . / bpd)) %>%
         mutate_at(vars(ac, bpd, hc),
                   funs(femur_ratio = . / femur)) %>%
         mutate_at(vars(ac, bpd, femur),
                   funs(hc_ratio = . / hc)) %>%
         ungroup() %>%
         select(-age) %>%
         gather(key, val, gage:hc,
                          ends_with('_square'),
                          ends_with('_cube'),
                          ends_with('_delta'),
                          ends_with('_ratio')) %>%
         unite(key2, key, scan_no, sep="_") %>%
         spread(key2, val) %>%
         mutate_at(vars(starts_with("gage_")),
                   funs(missing = is_null(.))) %>%
         mutate_at(vars(starts_with('gage_'), -ends_with('missing'),
                        starts_with('ac_'),
                        starts_with('bpd_'),
                        starts_with('femur_'),
                        starts_with('hc_')),
                   funs(coalesce(., 0)))

scans <- scans %>%
         inner_join(children, by="subject_id")

write_csv(scans, "datasets/scans.csv")

