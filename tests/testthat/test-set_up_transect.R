test_that("gives useful error messages", {
  expect_error(set_up_transect("blah", "blah", "blah", "blah"))
})
