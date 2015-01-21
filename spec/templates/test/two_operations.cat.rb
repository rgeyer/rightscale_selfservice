#test:execution_state=success
#test:execution_alternate_state=failed

name "Foo"
rs_ca_ver 20131202
short_description "Foo"

#test_operation:execution_state=success
#test_operation:execution_alternate_state=failed
#test_operation_param:key=val
#test_operation_param:key1=val1
#test_operation_param:key2=val2
operation "one" do
  description "one"
  definition "foo"
end

#test_operation:execution_state=success
#test_operation:execution_alternate_state=failed
#test_operation_param:key=val
#test_operation_param:key1=val1
#test_operation_param:key2=val2
operation "two" do
  description "two"
  definition "foo"
end

define foo() do

end
