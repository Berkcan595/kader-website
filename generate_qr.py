"""
generate_qr.py - Kader Website icin pembe/rose tonlarinda QR kod olusturur.

Gereksinimler:
    pip install qrcode pillow

Kullanim:
    python generate_qr.py
    python generate_qr.py --url "https://kulladiciniz.github.io/kader-website/"
"""
import argparse
import os

def main():
    parser = argparse.ArgumentParser(description="Kader website QR kod uretici")
    parser.add_argument(
        "--url",
        default="https://USERNAME.github.io/kader-website/",
        help="QR koduna gomulecek URL (varsayilan: GitHub Pages URL sablonu)"
    )
    parser.add_argument(
        "--output",
        default="qr.png",
        help="Cikti dosya adi (varsayilan: qr.png)"
    )
    args = parser.parse_args()

    try:
        import qrcode
        from PIL import Image, ImageDraw
    except ImportError:
        print("Hata: Gerekli kutuphaneler eksik.")
        print("Lutfen su komutu calistirin: pip install qrcode pillow")
        return

    url = args.url
    if "USERNAME" in url:
        print("UYARI: URL icinde 'USERNAME' yer tutucu var!")
        print("Lutfen gercek GitHub kulladicinizla degistirin:")
        print('  python generate_qr.py --url "https://kulladiciniz.github.io/kader-website/"')
        print()

    # QR olustur
    qr = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=12,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)

    # Pembe/rose tonlari
    img = qr.make_image(
        fill_color="#C94B7A",   # deep rose (karelerin rengi)
        back_color="#FFF0F7"    # blush beyaz (arka plan)
    )

    # PNG olarak kaydet
    img.save(args.output)
    abs_path = os.path.abspath(args.output)
    print(f"QR kod olusturuldu: {abs_path}")
    print(f"URL: {url}")
    print()
    print("Ipucu: qr.html sayfasini tarayicida acarak da QR kod indirebilirsiniz.")

if __name__ == "__main__":
    main()
