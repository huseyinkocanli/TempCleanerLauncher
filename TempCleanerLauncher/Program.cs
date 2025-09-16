/*
 * User: Thekocanl
 * Date: 16.09.2025
 * Time: 15:46
 */
using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

namespace TempCleanerLauncher
{
    /// <summary>
    /// PowerShell tabanlı TempCleaner uygulamasını başlatan ana program sınıfı.
    /// </summary>
    public static class Program
    {
        /// <summary>
        /// Uygulamanın ana giriş noktası.
        /// </summary>
        [STAThread]
        private static void Main()
        {
            // Başlatılacak olan PowerShell betik dosyasının adı.
            const string powershellScriptFileName = "TempCleaner.ps1";
            
            // Çalışan .exe dosyasının bulunduğu klasörün yolunu al.
            // Application.StartupPath, programın çalıştığı dizini güvenilir bir şekilde verir.
            string startupPath = Application.StartupPath;
            
            // PowerShell betiğinin tam yolunu oluştur.
            string scriptFullPath = Path.Combine(startupPath, powershellScriptFileName);

            // Betik dosyasının var olup olmadığını kontrol et.
            if (!File.Exists(scriptFullPath))
            {
                // Betik bulunamazsa kullanıcıyı bilgilendir ve programdan çık.
                MessageBox.Show(
                    $"Gerekli betik dosyası bulunamadı:\n\n{scriptFullPath}", 
                    "Başlatma Hatası", 
                    MessageBoxButtons.OK, 
                    MessageBoxIcon.Error);
                return;
            }
            
            // PowerShell.exe'yi başlatmak için yeni bir işlem (process) oluştur.
            var processInfo = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                
                // DEĞİŞİKLİK: Proje artık modern .NET'i hedeflediği için daha okunaklı olan
                // string interpolation ($"...") yöntemine geri dönüldü.
                Arguments = $"-ExecutionPolicy Bypass -File \"{scriptFullPath}\"",
                
                // Bu ayarlar PowerShell konsol penceresinin gizli kalmasını sağlar.
                UseShellExecute = false,
                CreateNoWindow = true 
            };
            
            try
            {
                // Hazırlanan ayarlarla işlemi başlat.
                Process.Start(processInfo);
            }
            catch (Exception ex)
            {
                // Beklenmedik bir hata olursa kullanıcıya detaylı bilgi ver.
                MessageBox.Show(
                    $"Program başlatılırken beklenmedik bir hata oluştu:\n\n{ex.Message}", 
                    "Kritik Hata", 
                    MessageBoxButtons.OK, 
                    MessageBoxIcon.Error);
            }
        }
    }
}
