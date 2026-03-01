// // ─── Sub-widgets ─────────────────────────────────────────────────────────────

// class _GenderSelector extends StatelessWidget {
//   const _GenderSelector({required this.gender, required this.onChanged});

//   final Gender gender;
//   final ValueChanged<Gender> onChanged;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(child: _button('乾造 男', Gender.male, const Color(0xFF8B3A3A))),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _button('坤造 女', Gender.female, const Color(0xFF4A6A6A)),
//         ),
//       ],
//     );
//   }

//   Widget _button(String label, Gender value, Color activeColor) {
//     final isSelected = gender == value;
//     return InkWell(
//       onTap: () => onChanged(value),
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 14),
//         decoration: BoxDecoration(
//           color: isSelected ? activeColor : Colors.transparent,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: isSelected ? activeColor : const Color(0xFF8B7E66),
//             width: 2,
//           ),
//         ),
//         child: Center(
//           child: Text(
//             label,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: isSelected ? Colors.white : const Color(0xFF5D4037),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ShiChenGrid extends StatelessWidget {
//   const _ShiChenGrid({required this.selected, required this.onChanged});

//   final String selected;
//   final ValueChanged<String> onChanged;

//   @override
//   Widget build(BuildContext context) {
//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 4,
//         childAspectRatio: 1.2,
//         crossAxisSpacing: 8,
//         mainAxisSpacing: 8,
//       ),
//       itemCount: shiChenList.length,
//       itemBuilder: (context, index) {
//         final sc = shiChenList[index];
//         final isSelected = selected == sc.name;
//         return InkWell(
//           onTap: () => onChanged(sc.name),
//           child: Container(
//             decoration: BoxDecoration(
//               color: isSelected ? const Color(0xFF8B3A3A) : Colors.white,
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                 color: isSelected
//                     ? const Color(0xFF5E2626)
//                     : const Color(0xFFC2BBA8),
//               ),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   sc.name,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: isSelected ? Colors.white : const Color(0xFF5D4037),
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   sc.range,
//                   style: TextStyle(
//                     fontSize: 10,
//                     color: isSelected ? Colors.white70 : Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class _BaziPreviewSection extends StatelessWidget {
//   const _BaziPreviewSection({required this.data});

//   final BaziCalculationResult data;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         const SizedBox(height: 24),
//         const Divider(),
//         const SizedBox(height: 16),
//         const Center(
//           child: Text(
//             '— 八字排盘结果 —',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF2F4545),
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             _pillar('年柱', data.yearPillar),
//             _pillar('月柱', data.monthPillar),
//             _pillar('日柱', data.dayPillar),
//             _pillar('时柱', data.hourPillar),
//           ],
//         ),
//         const SizedBox(height: 16),
//         Center(
//           child: RichText(
//             text: TextSpan(
//               style: const TextStyle(fontSize: 16, color: Color(0xFF5C7A6B)),
//               children: [
//                 const TextSpan(text: '起运年龄  '),
//                 TextSpan(
//                   text: '${data.startAge} 岁',
//                   style: const TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFFB22222),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _pillar(String label, String value) {
//     return Column(
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 12, color: Color(0xFF8B7E66)),
//         ),
//         const SizedBox(height: 4),
//         Column(
//           children: value.split('').map((char) {
//             return Text(
//               char,
//               style: const TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF2C2C2C),
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }
// }

// class _LifeEventsSection extends StatelessWidget {
//   const _LifeEventsSection({
//     required this.events,
//     required this.onAddTap,
//     required this.onRemoveAt,
//   });

//   final List<LifeEvent> events;
//   final VoidCallback onAddTap;
//   final ValueChanged<int> onRemoveAt;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Center(
//               child: Text(
//                 '— 过往人生大事(可选) —',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF2F4545),
//                 ),
//               ),
//             ),
//             TextButton.icon(
//               onPressed: () {
//                 FocusManager.instance.primaryFocus?.unfocus();
//                 onAddTap();
//               },
//               icon: const Icon(Icons.add, size: 18, color: Color(0xFF8B3A3A)),
//               label: const Text(
//                 '添加事件',
//                 style: TextStyle(color: Color(0xFF8B3A3A)),
//               ),
//             ),
//           ],
//         ),
//         if (events.isNotEmpty) ...[
//           const SizedBox(height: 8),
//           ...events.asMap().entries.map(
//             (entry) => _eventCard(entry.key, entry.value),
//           ),
//         ] else ...[
//           const SizedBox(height: 4),
//           const Text(
//             '添加您的重要人生节点，帮助 AI 校准运势预测',
//             style: TextStyle(fontSize: 13, color: Colors.grey),
//           ),
//         ],
//       ],
//     );
//   }

//   Widget _eventCard(int i, LifeEvent event) {
//     final isSmooth = event.outcome == EventOutcome.smooth;
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: const Color(0xFFC2BBA8)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//             decoration: BoxDecoration(
//               color: const Color(0xFF8B3A3A).withValues(alpha: 0.1),
//               borderRadius: BorderRadius.circular(4),
//             ),
//             child: Text(
//               event.type.label,
//               style: const TextStyle(fontSize: 12, color: Color(0xFF8B3A3A)),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               '${event.year}年${event.month != null ? '${event.month!.padLeft(2, '0')}月' : ''}  ${event.description}',
//               style: const TextStyle(fontSize: 14),
//             ),
//           ),
//           const SizedBox(width: 4),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//             decoration: BoxDecoration(
//               color: isSmooth ? Colors.green.shade50 : Colors.orange.shade50,
//               borderRadius: BorderRadius.circular(4),
//             ),
//             child: Text(
//               event.outcome.label,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: isSmooth
//                     ? Colors.green.shade700
//                     : Colors.orange.shade700,
//               ),
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.close, size: 18, color: Colors.grey),
//             padding: EdgeInsets.zero,
//             constraints: const BoxConstraints(),
//             onPressed: () => onRemoveAt(i),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _AddEventSheet extends StatefulWidget {
//   const _AddEventSheet({required this.onConfirm});

//   final ValueChanged<LifeEvent> onConfirm;

//   @override
//   State<_AddEventSheet> createState() => _AddEventSheetState();
// }

// class _AddEventSheetState extends State<_AddEventSheet> {
//   final _yearCtrl = TextEditingController();
//   final _descCtrl = TextEditingController();
//   int _granularity = 0; // 0=年, 1=年月, 2=年月日
//   int _selectedMonth = 1;
//   int _selectedDay = 1;
//   EventType _selectedType = EventType.career;
//   EventOutcome _selectedOutcome = EventOutcome.smooth;
//   String? _yearError;

//   @override
//   void dispose() {
//     _yearCtrl.dispose();
//     _descCtrl.dispose();
//     super.dispose();
//   }

//   void _onConfirm() {
//     final year = _yearCtrl.text.trim();
//     final desc = _descCtrl.text.trim();
//     if (year.isEmpty || desc.isEmpty) return;

//     final yearInt = int.tryParse(year);
//     if (yearInt == null || yearInt < 1900 || yearInt > 2100) {
//       setState(() => _yearError = '请输入 1900–2100 之间的有效年份');
//       return;
//     }

//     widget.onConfirm(
//       LifeEvent(
//         year: year,
//         month: _granularity >= 1
//             ? _selectedMonth.toString().padLeft(2, '0')
//             : null,
//         day: _granularity >= 2 ? _selectedDay.toString().padLeft(2, '0') : null,
//         description: desc,
//         type: _selectedType,
//         outcome: _selectedOutcome,
//       ),
//     );
//     Navigator.of(context).pop();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(
//         left: 20,
//         right: 20,
//         top: 20,
//         bottom: MediaQuery.of(context).viewInsets.bottom + 24,
//       ),
//       child: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Center(
//               child: Text(
//                 '添加人生大事',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF4A3B32),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               '时间粒度',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF4A3B32),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 _toggle(
//                   '年',
//                   _granularity == 0,
//                   () => setState(() => _granularity = 0),
//                 ),
//                 const SizedBox(width: 8),
//                 _toggle(
//                   '年月',
//                   _granularity == 1,
//                   () => setState(() => _granularity = 1),
//                 ),
//                 const SizedBox(width: 8),
//                 _toggle(
//                   '年月日',
//                   _granularity == 2,
//                   () => setState(() => _granularity = 2),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               '年份 *',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF4A3B32),
//               ),
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _yearCtrl,
//               keyboardType: TextInputType.number,
//               maxLength: 4,
//               inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//               onChanged: (_) {
//                 if (_yearError != null) setState(() => _yearError = null);
//               },
//               decoration: InputDecoration(
//                 hintText: '如 2026',
//                 counterText: '',
//                 errorText: _yearError,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 10,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             if (_granularity >= 1) ...[
//               const Text(
//                 '月份',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF4A3B32),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               DropdownButtonFormField<int>(
//                 initialValue: _selectedMonth,
//                 decoration: InputDecoration(
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   filled: true,
//                   fillColor: Colors.white,
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 10,
//                   ),
//                 ),
//                 items: List.generate(
//                   12,
//                   (i) =>
//                       DropdownMenuItem(value: i + 1, child: Text('${i + 1} 月')),
//                 ),
//                 onChanged: (v) => setState(() => _selectedMonth = v!),
//               ),
//               const SizedBox(height: 16),
//             ],
//             if (_granularity >= 2) ...[
//               const Text(
//                 '日期',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF4A3B32),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               DropdownButtonFormField<int>(
//                 initialValue: _selectedDay,
//                 decoration: InputDecoration(
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   filled: true,
//                   fillColor: Colors.white,
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 10,
//                   ),
//                 ),
//                 items: List.generate(
//                   31,
//                   (i) =>
//                       DropdownMenuItem(value: i + 1, child: Text('${i + 1} 日')),
//                 ),
//                 onChanged: (v) => setState(() => _selectedDay = v!),
//               ),
//               const SizedBox(height: 16),
//             ],
//             const Text(
//               '事件描述 *',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF4A3B32),
//               ),
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _descCtrl,
//               decoration: InputDecoration(
//                 hintText: '如：跳槽、结婚、创业',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 10,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               '事件类型',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF4A3B32),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: EventType.values
//                   .map(
//                     (t) => Padding(
//                       padding: const EdgeInsets.only(right: 8),
//                       child: _toggle(
//                         t.label,
//                         _selectedType == t,
//                         () => setState(() => _selectedType = t),
//                       ),
//                     ),
//                   )
//                   .toList(),
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               '结果',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF4A3B32),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 _toggle(
//                   '顺利',
//                   _selectedOutcome == EventOutcome.smooth,
//                   () => setState(() => _selectedOutcome = EventOutcome.smooth),
//                 ),
//                 const SizedBox(width: 8),
//                 _toggle(
//                   '不顺',
//                   _selectedOutcome == EventOutcome.difficult,
//                   () =>
//                       setState(() => _selectedOutcome = EventOutcome.difficult),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _onConfirm,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF8B3A3A),
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   '确认添加',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _toggle(String label, bool selected, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(8),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//         decoration: BoxDecoration(
//           color: selected ? const Color(0xFF8B3A3A) : Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: selected ? const Color(0xFF5E2626) : const Color(0xFFC2BBA8),
//           ),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//             color: selected ? Colors.white : const Color(0xFF5D4037),
//           ),
//         ),
//       ),
//     );
//   }
// }
