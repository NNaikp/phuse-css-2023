# phuse-css-2023
Repo for HoW: Recreating Environments on the Other Side with pharmaverse – A Practical Guide to Pass Environments Through the FDAs Submission Gateway Today

---


Hi there! Thank you so much for signing up for our workshop!

## Abstract

If you are working with R, you are probably working with a Posit Package Management (PPM) server or some package management mechanism that specifically fits your organisation.

Together with tools such as the package {renv}, these make up the backbone of keeping track of your local environment internally.

But what do you do when the FDA asks for all of your programs? From multiple trials using different internal/external packages?

In this workshop, we will use a real-world example of a submission from Novo Nordisk which elaborates on the first pilot submission from R consortium’s “R for submission” working group.

Together we will devise a practical guide that you can use internally and hopefully also in your ADRGs!

---

## Introduction to Novo Nordisk's example

In this section, we will introduce the real-world scenario from Novo Nordisk. We will describe the challenges that they faced and how they managed to overcome them. We will then go on to explain how the attendees can use the same tools and methodologies internally. If you did not already see it we highly recommend that you watch some of [this presentation](https://www.youtube.com/watch?v=t33dS17QHuA&list=RDCMUC3xfbCMLCw1Hh4dWop3XtHg&start_radio=1).

## Why is package management crucial?

When working with R projects in a regulated environment, tracking dependencies, and controlling versions is crucial. This section emphasizes the importance of effective package management, which is fundamental in ensuring a project's integrity and reproducibility. We will explore the challenges faced while preparing R projects for submission to regulatory agencies like the FDA and discuss solutions such as package management tools and the {renv} package.

## Introduction to {renv} Package

The {renv} package is a popular package management tool used by R programmers to ensure project-specific libraries' independence, reproducibility, and manageability. This section will introduce attendees to the {renv} package and its core functionalities. We will explore how to set up, create, and maintain self-contained, reproducible environments using {renv}. We will also discuss how to utilize {renv} in a submission.

## Introduction to {pkglite} Package

The {pkglite} package is a package that now resides under {pharmaverse}. Initially built by the data scientists at Merck, this package aims to solve a problem related to FDA's submission gateway. A compiled R package **can not** be submitted through the gateway as FDA requires that submitted programs are in ASCII format. To alleviate this, the {pkglite} package re-packages an R package's source to a text file that can pass through the submission gateway. We will display the functionality of the pkglite package and how it was used in the Novo Nordisk submission.

## The Analysis Data Reviewer's Guide (ADRG)

The ADRG plays a vital role in conveying information about data and programs to authorities. However, with an open-source language there are many complexities that needs to be accounted for and with a new language we cannot expect that everyone is at the same level of expertise. Because we have used SAS for so many years there are many aspects of that language where we share a common understanding. Imagine all of this is now gone - and we are to some extent starting from scratch. In this section we will look at all of the added complexities that needs to be noted down and explained in the ADRG. Attendees will also discuss and share their own ADRG recipes and which aspects they see as a "must-include" in an ADRG that is now trying to explained uncharted territory.

## The future toolchain for regulatory R environments and submissions

In this section we will discuss the R packages that could be a great starting point for any company wanting to do a submission in R - whether it be today, or in the future with docker images. We will take a closer look at some of the missing pieces of this puzzle and start a discussion on which parts of data and code handling that could ultimately be aligned across the pharma industry with configurable packages.

---






