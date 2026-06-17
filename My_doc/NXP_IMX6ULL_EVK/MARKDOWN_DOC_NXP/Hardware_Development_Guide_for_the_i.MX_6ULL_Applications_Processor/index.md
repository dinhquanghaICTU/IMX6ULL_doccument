# Hardware Development Guide for the i.MX 6ULL Applications Processor

Mục lục các chương trong tài liệu hướng dẫn thiết kế, layout, kiểm tra và bring-up phần cứng sử dụng bộ xử lý NXP i.MX 6ULL.

## Nội dung

1. [About This Book](1.%20About_This_Book.md)  
   Giới thiệu phạm vi tài liệu, đối tượng sử dụng, tài liệu tham khảo và các quy ước trình bày.

2. [i.MX 6ULL Design Checklist](2._i.MX_6ULL_Design_Checklist.md)  
   Checklist thiết kế cho DDR, boot mode, I2C, JTAG, nguồn, tụ decoupling và các giao tiếp phần cứng quan trọng.

3. [i.MX 6ULL Layout Recommendations](3._i.MX_6ULL_Layout_Recommendations.md)  
   Khuyến nghị bố trí PCB, stack-up, trở kháng, đặt tụ và routing các tín hiệu tốc độ cao, đặc biệt là DDR.

4. [Avoiding Board Bring-up Problems](4._Avoiding_Board_Bring-up%20_Problems.md)  
   Hướng dẫn kiểm tra nguồn, điện áp, clock và reset để tránh các lỗi phổ biến khi khởi động bo mạch lần đầu.

5. [Understanding the IBIS Model](5._Understanding_the_IBIS_Model.md)  
   Giải thích cấu trúc và cách dùng mô hình IBIS để mô phỏng signal integrity và timing ở cấp độ bo mạch.

6. [Using the Manufacturing Tool](6._Using_the_Manufacturing_Tool.md)  
   Giới thiệu cách kết nối, cài đặt và sử dụng i.MX Manufacturing Tool để nạp firmware hàng loạt qua USB.

7. [Using BSDL for Board-Level Testing](7._Using_BSDL_for_Board-Level_Testing.md)  
   Trình bày cách dùng BSDL và JTAG boundary scan để kiểm tra kết nối, phát hiện hở mạch hoặc chập mạch trên bo.

## Thứ tự đọc đề xuất

- Thiết kế schematic: đọc chương 2.
- Thiết kế và routing PCB: đọc chương 3.
- Bring-up bo mạch mới: đọc chương 4.
- Mô phỏng tín hiệu: đọc chương 5.
- Nạp firmware sản xuất: đọc chương 6.
- Kiểm tra bo sau lắp ráp: đọc chương 7.
