# دليل المطور: تطبيق الأمين الشرعي (API & Schema Reference)

هذا الدليل موجه لمطور تطبيق الجوال (الوكيل الآخر) لبناء التطبيق بناءً على هيكلية البيانات **الفعلية (Actual DB Schema)** ونقاط النهاية (API Endpoints) المعتمدة.

## 1. نظرة عامة على الكيانات (Entities Review)

### أ. الأمين الشرعي (`LegitimateGuardian`)

المصدر: جدول `legitimate_guardians`

* **المعرف**: `id` (Primary Key).
* **الاسم**:
  * `first_name` (اسم الأمين)
  * `father_name` (اسم الأب)
  * `grandfather_name` (اسم الجد)
  * `family_name` (اللقب)
* **الوثائق**:
  * `license_number`, `license_expiry_date` (الترخيص)
  * `profession_card_number`, `profession_card_expiry_date` (البطاقة)
* **التجديدات**:
  * `guardian_license_renewals` (جدول التجديدات)
  * `electronic_card_renewals` (جدول تجديد البطاقة)

### ب. دفاتر السجلات (`RecordBook`)

المصدر: جدول `record_books`

* **المعرف**: `id`
* **رقم الدفتر**: `book_number` (مهم جداً للربط)
* **الاسم**: `name`
* **السنة**: `hijri_year`
* **الحالة**: `status` ('active', 'closed', etc)
* **الصفحات**: `total_pages`, `start_constraint_number`, `end_constraint_number`

### ج. القيود/العقود (`RegistryEntry`) - الجدول المركزي

المصدر: جدول `registry_entries`
هذا هو الجدول "المركزي" الذي يربط كل العمليات.

* **المعرف**: `id`, `serial_number`.
* **النوع**: يحدده `contract_type_id` (زواج، طلاق، إلخ).
* **العلاقة (Polymorphic)**:
  * هذا الجدول يحتوي على بيانات "الرأس" (Header) فقط: الأطراف، التاريخ، المأذون.
  * تفاصيل العقد الدقيقة (مثل قيمة المهر في الزواج، أو عدد الطلقات) تُخزن في جداول منفصلة (مثل `marriage_contracts`, `divorce_contracts`).
  * يرتبط بها عبر: `constraintable_type` و `constraintable_id`.
  * **ملاحظة للمطور**: الـ API الحالي يتعامل مع الجدول المركزي فقط (إنشاء المسودة). التعامل مع التفاصيل (Children Tables) سيكون في مراحل لاحقة.
* **المعرف**: `id`, `serial_number` (الرقم التسلسلي للقيد)
* **الأطراف**:
  * `first_party_name` (الزوج/الموكل)
  * `second_party_name` (الزوجة/الطرف الآخر)
* **التواريخ**:
  * `document_gregorian_date`, `document_hijri_date`, `hijri_year`
* **الربط**:
  * `contract_type_id` (نوع العقد)
  * `guardian_record_book_id` (معرف الدفتر)
  * `guardian_page_number`, `guardian_entry_number` (يتم إخالهم يدوياً)
* **المالية**:
  * `fee_amount`, `penalty_amount`, `receipt_number`

---

## 2. نقاط النهاية (API Endpoints)

**Base URL**: `https://your-domain.com/api`
**Headers**:

* `Accept: application/json`
* `Authorization: Bearer <TOKEN>`

### 1. الرئيسية (Dashboard)

جلب إحصائيات، رسالة ترحيب، وحالة التراخيص.

* **GET** `/dashboard`
* **Response**:

    ```json
    {
      "meta": {
        "welcome_message": "مساء الخير، محمد",
        "date_gregorian": "الثلاثاء، 28 يناير 2026",
        "date_hijri": "9 شعبان 1447 هـ"
      },
      "stats": {
        "total_entries": 150,
        "total_drafts": 5,
        "total_documented": 140,
        "this_month_entries": 12
      },
      "status_summary": {
        "license": {
          "status_label": "سارية",
          "status_color": "success",
          "expiry_date": "2027-05-20",
          "days_remaining": 450
        },
        "card": { ... }
      },
      "recent_activities": [ ... ]
    }
    ```

### 2. السجلات (My Records)

عرض قائمة الدفاتر ونسبة امتلائها.

* **GET** `/record-books`
* **Response List**:

    ```json
    {
      "date": [
        {
          "id": 101,
          "book_number": 5,
          "name": "سجل عقود الزواج - 2025",
          "contract_type_name": "عقد زواج",
          "total_pages": 50,
          "constraints_count": 12,
          "used_percentage": 24,
          "status_label": "نشط",
          "status_color": "success"
        }
      ]
    }
    ```

### 3. عمليات القيود (Registry Entries)

#### أ. قائمة القيود

* **GET** `/registry-entries`
* **Query Params**: `?page=1`, `?status=draft`, `?search=اسم`

#### ب. إضافة قيد جديد (Draft)

هذا هو الـ Endpoint الأهم لإنشاء العقود من التطبيق.

* **POST** `/registry-entries`
* **Body (Form Data)** - **أسماء الحقول الفعلية**:

    | Field | Type | Required | Description |
    |---|---|---|---|
    | `record_book_id` | Int | **Yes** | `id` من استجابة `/record-books` |
    | `contract_type_id` | Int | **Yes** | معرف نوع العقد (زواج=1) |
    | `transaction_date` | Date | **Yes** | `YYYY-MM-DD` (يتم تخزينه في `document_gregorian_date`) |
    | `first_party_name` | String | **Yes** | `first_party_name` في الجدول |
    | `second_party_name` | String | **Yes** | `second_party_name` في الجدول |
    | `guardian_page_number`| Int | No | `guardian_page_number` |
    | `guardian_entry_number`| Int | No | `guardian_entry_number` |
    | `notes` | String | No | `notes` |

* **ملاحظة هامة:** عند الحفظ، يقوم النظام تلقائياً بملء:
  * `status` = 'draft'
  * `writer_type` = 'guardian'
  * `hijri_year` = السنة من التاريخ المدخل
  * `document_hijri_date` = تحويل التاريخ المدخل

---

## 3. التعليمات الهيكلية (Architecture Instructions)

1. **Repository Pattern**: افصل الـ Data Layer عن الـ UI.
2. **Clean Models**:
    * قم بإنشاء كلاس `Guardian` واسحب الاسم من `first_name` + `family_name`.
    * استخدم `RegistryEntry` للحقول القادمة من API القيود.
3. **الألوان**:
    * الخادم يرسل `status_color` كنص ('success', 'danger').
    * اعتمد `Map<String, Color>` لتوحيد الألوان في التطبيق.

---
**تحذير**: لا تحاول تخمين أسماء الأعمدة. التزم بالمذكور في هذا الملف حيث تم استخراجه من قاعدة البيانات مباشرة (`php artisan model:show`).
