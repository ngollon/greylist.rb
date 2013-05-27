greylist.rb
===========

Simple ruby based greylisting implementation using the filesystem as its database. Designed for use with exim, but may be useful elsewhere.

Sample exim configuration
-------------------------

```
# Greylist.rb
defer log_message = greylisted host $sender_host_address
      set acl_m0  = ${readsocket{/var/run/greylist/greylist.sock}{$sender_host_address $local_part}{5s}}
      message     = ${substr_1:$acl_m0}
      condition   = ${if eq {${substr_0_1:$acl_m0}} {!} }

# Add a warning message to the mail if its been delayed
warn log_message = greylist retry successful for host $sender_host_address
     message     = ${substr_1:$acl_m0}
     condition   = ${if eq {${substr_0_1:$acl_m0}} {:} }

# Add a log message for greylist feedback
warn log_message = greylist message ${substr_1:$acl_m0}
     condition   = ${if eq {${substr_0_1:$acl_m0}} {.} }
```