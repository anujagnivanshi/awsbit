# -*- coding: utf-8 -*-
"""
(c) 2015 Infor, inc. All Rights Reserved
"""
__author__ = "test"
__credits__ = ["test", "Abul"]

from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support.ui import Select
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
import datetime

class CloudSuite():
    """Class for cloudsuite portal common oparations"""
    
    def login(self, url, username, password, driver):
        "Login into the CloudSuite Portal"
      
        driver = driver
        driver.get(url)
        assert "Infor CloudSuite" == driver.title

        user_name_element_location = driver.find_element_by_id("j_username")
        user_name_element = WebDriverWait(driver, 10).until(lambda driver: user_name_element_location)
        user_name_element.clear()
        user_name_element.send_keys(username)

        password_element_location = driver.find_element_by_id("j_password")
        password_element = WebDriverWait(driver, 10).until(lambda driver: password_element_location)
        password_element.clear()
        password_element.send_keys(password)

        login_button_element_location = driver.find_element_by_id("cloud_login_submit")
        login_button_element = WebDriverWait(driver, 10).until(lambda driver: login_button_element_location)
        login_button_element.click()

        login_check_element = WebDriverWait(driver, 60).until(lambda driver: \
                                                              driver.find_element_by_xpath("//span[@class=\
                                                              'user-name-text']"))
        login_user_name = login_check_element.text
        assert username[:19] in login_user_name

    def select_deployed_product(self, deployment_name, driver):
        """select the given product in cloudsuite portal"""
        
        WebDriverWait(driver, 120).until(EC.presence_of_element_located((By.ID, "global-deployments-list-grid")))

        WebDriverWait(driver, 120).until(EC.invisibility_of_element_located((By.XPATH, "//div[@class='disabled']")))
        deploy_button_element = WebDriverWait(driver, 300).until(EC.invisibility_of_element_located \
                                                                 ((By.XPATH, "//div[@class='loading-overlay']")))

        search_box = driver.find_element_by_id("deployment-list-search-box")
        search_box.clear()
        search_box.send_keys(deployment_name)
        driver.find_element_by_id("refresh-deployments-list").click()
       
        product_element = "//div[contains(text(), '"+deployment_name+"') and @class='deployment-name']/parent::div"

        WebDriverWait(driver, 120).until(EC.invisibility_of_element_located \
                                                                ((By.XPATH, "//div[@class='loading-overlay']")))

        try:
            WebDriverWait(driver, 120).until(EC.presence_of_element_located((By.XPATH, product_element)))
        except TimeoutException:
            return "Deleted"
        
        WebDriverWait(driver, 10).until(EC.visibility_of(driver.find_element_by_xpath(product_element)))
        driver.find_element_by_xpath(product_element).click()
        assert deployment_name == driver.find_element_by_xpath("//div[@class='deployment-name']").text
    
    def status_check(self, deployment_name, driver):
        """Deployment status check in cloud suite portal"""
        
        status = self.select_deployed_product(deployment_name, driver)
        if status == 'Deleted':
            return status
        
        status_Xpath = "//div[@class='deployment-slide info-slide']//div[@class='big-info-row state']//div[@class='value']"
        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.XPATH, status_Xpath)))
        status_element = driver.find_element_by_xpath(status_Xpath)
        status = status_element.get_attribute('innerHTML')
        return status

    def delete_deployment(self, deployment_name, driver):
        """Delete deployment from CloudSuite portal"""
        
        self.select_deployed_product(deployment_name, driver)
        
        driver.find_element_by_xpath("//div[contains(text(), 'Delete')]").click()

        driver.find_element_by_id('delete-verify-string').send_keys('YES')
        driver.find_element_by_id('delete_deployment').click()
        #driver.find_element_by_id('delete_cancel').click()
                  
        status_Xpath = "//div[@class='deployment-slide info-slide']//div[@class='big-info-row state']//div[@class='value']"
        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.XPATH, status_Xpath)))
        status_element = driver.find_element_by_xpath(status_Xpath)
        status = status_element.get_attribute('innerHTML')
        assert status == "Cf:Terminating..."
        return status
        
        

        
