# Vessel log tests
test_that("Vessel_Log is dataframe", {
  expect_true(is.data.frame(Vessel_Log), data.frame)
})

# Trawl depths tests
test_that("Trawl_Depths is dataframe", {
  expect_true(is.data.frame(Trawl_Depths), data.frame)
})

# Effort allocation test
test_that("Effort_Allocation is dataframe", {
  expect_true(is.data.frame(Effort_Allocation), data.frame)
})

test_that("Effort_Allocation has all basins", {
  expect_true(all("WB" %in% Effort_Allocation$BASIN,
                  "CB" %in% Effort_Allocation$BASIN,
                  "EB" %in% Effort_Allocation$BASIN))
})

