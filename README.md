# globus-metrics
script to parse globus transfer usage data

Rscript globus-usage.R -h 

Options:
	-f CHARACTER, --file=CHARACTER
		globus usage tranger file name

	-o CHARACTER, --out=CHARACTER
		output file name [default= out.xslx]

	-s CHARACTER, --start=CHARACTER
		the start date for globus transfers for the report (YYYY-MM-DD)

	-e CHARACTER, --end=CHARACTER
		the end date for globus transfers for the report (YYYY-MM-DD)

	-h, --help
		Show this help message and exit
    

Example usage

Rscript globus-usage.R -f Globus_Usage_Transfer_Detail.csv -o globus-report-092015-082016.xlsx -s 2015-09-01 -e 2016-08-31
