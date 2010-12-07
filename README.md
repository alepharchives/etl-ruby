# Ruby ETL

This is a small chunk of a larger framework that was developed in 2008 and is no longer in use. Prior to completely open sourcing it, we discovered some licensing (and other) issues that meant we could not proceed. As a result, this repository contains a subset of the origin project code, which is *not* fit for general use. In particular

- The code base is incomplete, with only the log and LDAP/LDIFF processing pipelines working properly 
- Not all of the tests pass (because some of the test data could not be released into the public domain)
- None of the integration tests are available and neither are the environment details that some of the functional tests depend upon

I've pushed this code to github ahead of a potential rewrite and/or merge with other open source ruby ETL tools, and for reference purposes. 