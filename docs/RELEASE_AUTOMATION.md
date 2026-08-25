# Publikasi Otomatis Valtique

Workflow [`.github/workflows/publish-release.yml`](../.github/workflows/publish-release.yml) membuat ZIP shaderpack langsung dari commit yang dipilih, memvalidasi integritas ZIP, lalu menerbitkan artefak yang sama ke **Modrinth** dan **CurseForge**. Workflow tidak membuat maupun mengubah GitHub Release. Publikasi berjalan ketika tag Git yang sesuai pola `v*` didorong ke GitHub atau ketika workflow dipicu secara manual dari tab **Actions**.

> Workflow tidak menggunakan username atau password. Token disimpan sebagai **GitHub Actions Secrets**, sehingga nilainya tidak disimpan dalam repositori maupun ditampilkan pada log normal workflow.

| Secret repositori | Kegunaan | Cara membuat |
|---|---|---|
| `MODRINTH_TOKEN` | Mengizinkan pembuatan versi pada proyek Modrinth `3FUsMjv8`. | Buat personal access token pada [pengaturan akun Modrinth](https://modrinth.com/settings/account) dengan izin `VERSION_CREATE`. |
| `CURSEFORGE_TOKEN` | Mengizinkan unggahan file pada proyek CurseForge `1640421`. | Buat token pada [halaman API Tokens CurseForge](https://authors-old.curseforge.com/account/api-tokens). |

## Konfigurasi Sekali Saja

Buka repositori GitHub Valtique, lalu masuk ke **Settings → Secrets and variables → Actions → New repository secret**. Tambahkan kedua secret dengan nama yang persis sama seperti tabel di atas. Nilai token hanya perlu ditambahkan pada GitHub; jangan pernah ditulis ke berkas workflow, commit, issue, atau chat publik.

Setelah dua secret tersedia, gunakan tag rilis dengan format semver berawalan `v`, misalnya `v5.5.0`. Mendorong tag tersebut akan membangun ZIP dari commit tag dan menjalankan publikasi ke dua platform.

```bash
git tag v5.5.0
git push origin v5.5.0
```

Workflow juga dapat dijalankan secara manual dari tab **Actions** dengan tiga input: `version`, daftar `minecraft_versions` untuk Modrinth, serta daftar `curseforge_game_versions` untuk CurseForge. Nilai bawaan adalah Minecraft `1.21.11` pada Modrinth dan `Iris,1.21.11` pada CurseForge. Channel rilis dapat dipilih sebagai `release`, `beta`, atau `alpha`.

## Perilaku Publikasi

Untuk Modrinth, workflow membuat versi baru dengan loader `iris`, lingkungan `client_only`, dan metadata versi Minecraft yang Anda pilih. Untuk CurseForge, workflow mengambil katalog versi game saat berjalan, memetakan nama yang dimasukkan ke ID yang dibutuhkan API, kemudian mengunggah ZIP dan changelog Markdown. Artifact ZIP sementara disimpan hanya untuk membagikan berkas yang sama kepada dua job unggahan.

Jika salah satu platform menolak rilis, job platform lainnya tetap memberikan hasilnya sendiri. Jangan memicu ulang seluruh workflow tanpa membaca log: jika Modrinth sudah sukses tetapi CurseForge gagal, jalankan ulang hanya job CurseForge setelah penyebabnya diperbaiki agar Modrinth tidak mencoba membuat versi duplikat.

## Referensi

[1]: https://docs.modrinth.com/api/operations/createversion/ "Modrinth API — Create a version"
[2]: https://docs.modrinth.com/api/ "Modrinth API — Authentication"
[3]: https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api "CurseForge Upload API"
