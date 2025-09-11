# vitis -s setup.py hello1
# vitis --workspace ./workspace/

import vitis
import os
import sys

app_name = sys.argv[1]
print("********* app_name = ", app_name)

plat_name = "standalone_plat"
hw_xsa = "../implement/results/top.xsa"
cpu_name = "microblaze_0"
#cpu_name = "psu_cortexa53_0"

os.system('rm -rf workspace')

client = vitis.create_client()
client.set_workspace(path="workspace")

advanced_options = client.create_advanced_options_dict(dt_overlay="0")

platform = client.create_platform_component(
    name = plat_name,
    hw_design = hw_xsa,
    os = "standalone",
    cpu = cpu_name,
    domain_name = "standalone_domain_0",
    generate_dtb = False,
    advanced_options = advanced_options
    #compiler = "gcc"
)
print("**********platform created");

#platform = client.get_component(name=plat_name)

status = platform.build()
print("********** platform built, status = ", status);

# create empty application
comp = client.create_app_component(
    name = app_name,
    platform = "./workspace/standalone_plat/export/standalone_plat/standalone_plat.xpfm",
    domain = "standalone_domain_0",
    template = "empty_application"
)
print("********** app_created");

# add source files as symbolic links
os.system(f"ln -s ../../../src/{app_name}/test.c workspace/{app_name}/src/test.c")
os.system(f'ln -s ../../../src/fpga.h workspace/{app_name}/src/fpga.h')
print("******* symbolic links made");

status = comp.clean()
status = platform.build()
comp.build()
vitis.dispose()

