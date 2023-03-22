# Appendix

### Current VM sizes supported by PCoIP Graphics Agents

[NCasT4_v3-series VMs](https://docs.microsoft.com/en-us/azure/virtual-machines/nct4-v3-series) powered by **NVIDIA Tesla T4 GPUs**.
|**Size**|**vCPU**|**Memory: GiB**|**Temp storage (SSD) GiB**|**GPU**|**GPU memory: GiB**|**Max data disks**|**Max NICs / Expected network bandwidth (Mbps)**|
|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
|**Standard_NC4as_T4_v3**|4|28|180|1|16|8|2 / 8000|
|**Standard_NC8as_T4_v3**|8|56|360|1|16|16|4 / 8000|
|**Standard_NC16as_T4_v3**|16|110|360|1|16|32|8 / 8000|
|**Standard_NC64as_T4_v3**|64|440|2880|4|64|32|8 / 32000|

[NV-series VMs](https://docs.microsoft.com/en-us/azure/virtual-machines/nv-series) powered by **NVIDIA Tesla M60 GPUs**.
|**Size**|**vCPU**|**Memory: GiB**|**Temp storage (SSD) GiB**|**GPU**|**GPU memory: GiB**|**Max data disks**|**Max NICs**|**Virtual Workstations**|**Virtual Applications**|
|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
|**Standard_NV6**|6|56|340|1|8|24|1|1|25|
|**Standard_NV12**|12|112|680|2|16|48|2|2|50|
|**Standard_NV24**|24|224|1440|4|32|64|4|4|100|

[NVv3-series VMs](https://docs.microsoft.com/en-us/azure/virtual-machines/nvv3-series) powered by **NVIDIA Tesla M60 GPUs**.
|**Size**|**vCPU**|**Memory: GiB**|**Temp storage (SSD) GiB**|**GPU**|**GPU memory: GiB**|**Max data disks**|**Max uncached disk throughput: IOPS/MBps**|**Max NICs**|**Expected network bandwidth (Mbps)**|**Virtual Workstations**|**Virtual Applications**|
|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
|**Standard_NV12s_v3**|12|112|320|1|8|12|20000/200|4|6000|1|25|
|**Standard_NV24s_v3**|24|224|640|2|16|24|40000/400|8|12000|2|50|
|**Standard_NV48s_v3**|48|448|1280|4|32|32|80000/800|8|24000|4|100|

[NVv4-series VMs](https://learn.microsoft.com/en-us/azure/virtual-machines/nvv4-series) powered by **AMD Radeon Instinct MI25 GPUs**.
|**Size**|**vCPU**|**Memory: GiB**|**Temp storage (SSD) GiB**|**GPU**|**GPU memory: GiB**|**Max data disks**|**Max uncached disk throughput: IOPS/MBps**|**Max NICs / Expected network bandwidth (MBps)**|
|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
|**Standard_NV4as_v4**|4|14|88|1/8|2|4|6400/96|2/1000|
|**Standard_NV8as_v4**|8|28|176|1/4|4|8|12800/192|4/2000|
|**Standard_NV16as_v4**|16|56|352|1/2|8|16|25600/384|8/4000|
|**Standard_NV32as_v4**|32|112|704|1|16|32|51200/768|8/8000|