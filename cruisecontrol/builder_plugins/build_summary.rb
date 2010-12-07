require 'rubygems'
require 'hpricot'

GREEN = 'background-color:#8F8'
RED = 'background-color:#F88'

class BuildSummary
    def initialize project
        @project = project
    end

    def build_finished error
        @report_dir = @project.last_build.artifacts_directory
        File.open File.expand_path(@report_dir + '/summary.html'), 'w' do |f|
            f.write <<-EOF
      <?xml version="1.0" encoding="iso-8859-1"?>
      <!DOCTYPE html
           PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
           "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
      <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
        <head>
          <title>Build report for #{@project.last_build.label}</title>
        </head>
        <body>
          <div style="white-space:normal;font-family:Arial,Helvetica,sans-serif;font-size:9pt;color:black">
            <h1 style="font-size:12pt;font-weight:bold;text-align:left">Build report</h1>
            <h2 style="font-size:10pt;font-weight:bold;text-align:left">etl4r</h2>
            <div id="summaryTable" style="white-space:normal;font-family:Arial,Helvetica,sans-serif;font-size:9pt;color:black">
              <table width="100%">
            EOF
            summarise_specs f
            summarise_coverage f
            summarise_integration f
            f.write <<-EOF
              </table>
            </div>
          </div>
        </body>
      </html>
            EOF
        end
    end

    private

    def process_specs specs_file, out
        if File.exist? specs_file
            specs = Hpricot(open(specs_file))
            totals = ( specs/"//script[text()*='totals']" ).inner_html.sub( /.*\"(.*)\".*/, "\\1" )
            pass = totals =~ /, 0/
            result_row out, pass, "Errors/failures", "#{totals} (0 allowed)"
        else
            report_not_available out
        end
    end

    def summarise_specs out
        spec_path = 'test_results/index.html'
        header_row out, "Spec (unit test) Results", 'test_results'
        specs_file = "#{@report_dir}/#{spec_path}"
        process_specs specs_file, out
        
        spec_path = 'test_results/sql_spec_index.html'
        header_row out, "Spec (sql unit test) Results", 'test_results/sql_spec_index.html'
        specs_file = "#{@report_dir}/#{spec_path}"
        process_specs specs_file, out
    end

    def summarise_coverage out
        coverage_path = 'coverage/index.html'
        header_row out, "Coverage Results", "coverage"
        coverage_file = "#{@report_dir}/#{coverage_path}"
        if File.exist? coverage_file
            coverage = Hpricot(open(coverage_file))
            code_lines = (coverage/"//tr[1]/td[3]/tt").inner_html
            code_coverage = (coverage/"//tr[1]/td[5]//tt").inner_html
            pass = code_coverage =~ /[9|10]\.[\d]{2}%/
            result_row out, pass, "Code lines", "#{code_lines} lines, coverage #{code_coverage} (90% required)"
        else
            report_not_available out
        end
    end

    def summarise_integration out
        test_path = 'integration_test_results/index.html'
        header_row out, "Integration Test Results", 'integration_test_results'
        specs_file = "#{@report_dir}/#{test_path}"
        process_specs specs_file, out
    end

    def header_row out, text, url
        out.write <<-EOF
            <tr>
                <th colspan="3">
                    <hr/>
                    <h3 style="font-size:10pt;font-weight:normal;text-align:left;color:blue">
                        <a href='/builds/etl4r/#{@project.last_build.label}/#{url}' >
                            #{text}
                        </a>
                    </h3>
                </th>
            </tr>
        EOF
        ##{url ? "<a href=\""+@project.last_build.label+"/"+url+"\">"+text+"</a>" : text}
    end

    def result_row out, pass, desc, result
        out.write <<-EOF
            <tr>
                <td><img src="/images/#{pass ? "pass" : "fail"}.png" alt="#{pass ? "pass" : "fail"}" /></td>
                <td>#{desc}</td>
                <td style="color:#{pass ? 'green' : 'red'}">#{result}</td>
            </tr>
        EOF
    end

    def report_not_available out, desc = ""
        result_row out, false, desc, "Not available"
    end

end

Project.plugin :build_summary
