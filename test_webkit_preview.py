#coding: utf-8
from selenium.webdriver.common.by import By
from selenium import webdriver
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import unittest
import time

class WebKitFeatureStatusTest(unittest.TestCase):

    def setUp(self):
        self.driver = webdriver.Safari(executable_path='/Applications/Safari Technology Preview.app/Contents/MacOS/safaridriver')
        self.driver.maximize_window()
        self.driver.implicitly_wait(10)

    def tearDown(self):
        self.driver.quit()

    def test_feature_status_page_search(self):
        self.driver.get("https://webkit.org/status/")

        # Enter "CSS" into the search box.
        # Ensures that at least one result appears in search
        search_box = self.driver.find_element_by_id("search")
        search_box.send_keys("CSS")
        value = search_box.get_attribute("value")
        self.assertTrue(len(value) > 0)
        search_box.submit()
        # Count the visible results when filters are applied
        # so one result shows up in at most one filter
        feature_count = self.shown_feature_count()
        print(feature_count)
        self.assertTrue(feature_count > 0)

    def test_feature_status_page_filters(self):
        self.driver.get("https://webkit.org/status/")

        wait = WebDriverWait(self.driver, 100)
        wait.until(EC.presence_of_element_located((By.CLASS_NAME, "filter-toggle")))
        filters = self.driver.execute_script("return document.querySelectorAll('.filter-toggle')")
        print("filters found:", *filters, sep = "\n")
        self.assertTrue(len(filters) > 0)

        # Make sure every filter is turned off.
        for checked_filter in filter(lambda f: f.is_selected(), filters):
            checked_filter.click()

    def shown_feature_count(self):
        wait = WebDriverWait(self.driver, 100)
        wait.until(lambda driver:len(driver.execute_script("return document.querySelectorAll('li.feature:not(.is-hidden)')"))>0)
        return len(self.driver.execute_script("return document.querySelectorAll('li.feature:not(.is-hidden)')"))


if __name__ == "__main__":
    unittest.main()
