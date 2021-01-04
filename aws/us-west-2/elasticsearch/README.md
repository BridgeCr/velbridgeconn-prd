# NOTICE
If starting new, make sure to apply security groups before applying the instance.

There's also a defect in the module that isn't applying our custom-generated security group, so there had to be manual additions added to the generated security group. If you run an apply, it will remoe these rules and prevent us access to the ES instance.