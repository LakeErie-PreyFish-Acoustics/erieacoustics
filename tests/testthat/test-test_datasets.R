# Vessel log tests

test_that("Vessel_Log is dataframe", {
  data("Vessel_Log")
  expect_true(is.data.frame(Vessel_Log), data.frame)
})

# Trawl depths tests
test_that("Trawl_Depths is dataframe", {
  data("Trawl_Depths")
  expect_true(is.data.frame(Trawl_Depths), data.frame)
})

# Effort allocation test
test_that("Effort_Allocation is dataframe", {
  data("Effort_Allocation")
  expect_true(is.data.frame(Effort_Allocation), data.frame)
})

test_that("Effort_Allocation has all basins", {
  data("Effort_Allocation")
  expect_true(all("WB" %in% Effort_Allocation$BASIN,
                  "CB" %in% Effort_Allocation$BASIN,
                  "EB" %in% Effort_Allocation$BASIN))
})

