$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$htmlPath = "D:\Riscv_proj\smart_controlsoc\doc\Course_Project_Report.html"
$pdfPath = "D:\Riscv_proj\smart_controlsoc\doc\Course_Project_Report.pdf"

if (-not (Test-Path $htmlPath)) {
    Write-Error "HTML file does not exist: $htmlPath"
    exit 1
}

$fileUrl = "file:///" + $htmlPath.Replace("\", "/")
Write-Output "Converting $fileUrl to PDF..."

# Run Edge with flags to disable browser-generated header and footer
$process = Start-Process -FilePath $edge -ArgumentList @(
    "--headless",
    "--disable-gpu",
    "--no-pdf-header-footer",
    "--print-to-pdf-no-header",
    "--print-to-pdf=$pdfPath",
    $fileUrl
) -Wait -PassThru

Write-Output "Exit code: $($process.ExitCode)"

if (Test-Path $pdfPath) {
    $item = Get-Item $pdfPath
    Write-Output "PDF generated successfully!"
    Write-Output "File Name: $($item.Name)"
    Write-Output "File Size: $($item.Length) bytes ($([math]::Round($item.Length / 1MB, 2)) MB)"
} else {
    Write-Error "PDF generation failed. Output file not found."
    exit 1
}
