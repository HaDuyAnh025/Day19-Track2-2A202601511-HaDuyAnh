# Reflection — Lab 19

**Tên:** _HÀ DUY ANH_
**Cohort:** _A20-K3_
**Path đã chạy:** lite

---

## Câu hỏi (≤ 200 chữ)

> Trên golden set 50 queries, mode nào thắng ở loại query nào (`exact` /
> `paraphrase` / `mixed`), và tại sao? Khi nào bạn **không** dùng hybrid
> (i.e. khi nào pure BM25 hoặc pure vector là lựa chọn đúng)? 

Kết quả đo trên golden set (Precision@10 trung bình): Keyword 77.8%, Semantic
73.2%, Hybrid 78.6%. Chia theo loại query: ở `exact` (15 câu), Keyword và
Hybrid ngang nhau (96.7%) vì từ khóa xuất hiện verbatim trong corpus nên
BM25 đã đủ tín hiệu, cộng thêm Vector qua RRF không thay đổi thứ hạng. Ở
`paraphrase` (15 câu), cả ba mode đều yếu (Keyword 33.3%, Hybrid 32.0%,
Semantic 24.0%) — Semantic thua chứ không thắng như kỳ vọng, vì
`bge-small-en-v1.5` là model tiếng Anh, semantic recall trên diễn đạt lại
tiếng Việt kém. Ở `mixed` (20 câu, vừa có từ khóa vừa có ý paraphrase),
Hybrid thắng rõ nhất (100% so với Keyword 97.0%, Semantic 98.5%) vì kết hợp
được cả hai tín hiệu.

Tôi sẽ không dùng Hybrid khi: (1) query gần như chắc chắn là exact-match
(mã lỗi, ID, tên riêng) và latency quan trọng — Keyword nhanh hơn Hybrid
~30 lần (P50 4.3ms so với 146.8ms) mà chất lượng tương đương; (2) corpus/
domain chưa có embedding model phù hợp ngôn ngữ — lúc đó Vector chỉ thêm
nhiễu và chi phí mà không thêm recall thật.

---

## Điều ngạc nhiên nhất khi làm lab này

Semantic search lại **thua** Keyword trên câu hỏi paraphrase tiếng Việt
(24.0% so với 33.3%) — ngược hoàn toàn với lý thuyết "vector thắng
paraphrase", vì embedding model chọn cho lab là model tiếng Anh.

---

## Bonus challenge

- [ ] Đã làm bonus (xem `bonus/`)
- [ ] Pair work với: _<tên đồng đội nếu có>_
