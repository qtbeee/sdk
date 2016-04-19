# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file contains all dart, css, and html sources for Observatory.
{
  'sources': [
    'lib/app.dart',
    'lib/cli.dart',
    'lib/cpu_profile.dart',
    'lib/debugger.dart',
    'lib/elements.dart',
    'lib/elements.html',
    'lib/object_graph.dart',
    'lib/service.dart',
    'lib/service_common.dart',
    'lib/service_io.dart',
    'lib/service_html.dart',
    'lib/src/app/analytics.dart',
    'lib/src/app/application.dart',
    'lib/src/app/location_manager.dart',
    'lib/src/app/page.dart',
    'lib/src/app/settings.dart',
    'lib/src/app/target_manager.dart',
    'lib/src/app/view_model.dart',
    'lib/src/cli/command.dart',
    'lib/src/cpu_profile/cpu_profile.dart',
    'lib/src/debugger/debugger.dart',
    'lib/src/debugger/debugger_location.dart',
    'lib/src/elements/action_link.dart',
    'lib/src/elements/action_link.html',
    'lib/src/elements/class_ref.dart',
    'lib/src/elements/class_ref.html',
    'lib/src/elements/class_tree.dart',
    'lib/src/elements/class_tree.html',
    'lib/src/elements/class_view.dart',
    'lib/src/elements/class_view.html',
    'lib/src/elements/code_ref.dart',
    'lib/src/elements/code_ref.html',
    'lib/src/elements/code_view.dart',
    'lib/src/elements/code_view.html',
    'lib/src/elements/context_ref.dart',
    'lib/src/elements/context_ref.html',
    'lib/src/elements/context_view.dart',
    'lib/src/elements/context_view.html',
    'lib/src/elements/cpu_profile.dart',
    'lib/src/elements/cpu_profile.html',
    'lib/src/elements/curly_block.dart',
    'lib/src/elements/curly_block.html',
    'lib/src/elements/debugger.dart',
    'lib/src/elements/debugger.html',
    'lib/src/elements/error_ref.dart',
    'lib/src/elements/error_ref.html',
    'lib/src/elements/error_view.dart',
    'lib/src/elements/error_view.html',
    'lib/src/elements/eval_box.dart',
    'lib/src/elements/eval_box.html',
    'lib/src/elements/eval_link.dart',
    'lib/src/elements/eval_link.html',
    'lib/src/elements/field_ref.dart',
    'lib/src/elements/field_ref.html',
    'lib/src/elements/field_view.dart',
    'lib/src/elements/field_view.html',
    'lib/src/elements/flag_list.dart',
    'lib/src/elements/flag_list.html',
    'lib/src/elements/function_ref.dart',
    'lib/src/elements/function_ref.html',
    'lib/src/elements/function_view.dart',
    'lib/src/elements/function_view.html',
    'lib/src/elements/general_error.dart',
    'lib/src/elements/general_error.html',
    'lib/src/elements/heap_map.dart',
    'lib/src/elements/heap_map.html',
    'lib/src/elements/heap_profile.dart',
    'lib/src/elements/heap_profile.html',
    'lib/src/elements/heap_snapshot.dart',
    'lib/src/elements/heap_snapshot.html',
    'lib/src/elements/icdata_view.dart',
    'lib/src/elements/icdata_view.html',
    'lib/src/elements/inbound_reference.dart',
    'lib/src/elements/inbound_reference.html',
    'lib/src/elements/instance_ref.dart',
    'lib/src/elements/instance_ref.html',
    'lib/src/elements/instance_view.dart',
    'lib/src/elements/instance_view.html',
    'lib/src/elements/instructions_view.dart',
    'lib/src/elements/instructions_view.html',
    'lib/src/elements/io_view.dart',
    'lib/src/elements/io_view.html',
    'lib/src/elements/isolate_reconnect.dart',
    'lib/src/elements/isolate_reconnect.html',
    'lib/src/elements/isolate_ref.dart',
    'lib/src/elements/isolate_ref.html',
    'lib/src/elements/isolate_summary.dart',
    'lib/src/elements/isolate_summary.html',
    'lib/src/elements/isolate_view.dart',
    'lib/src/elements/isolate_view.html',
    'lib/src/elements/json_view.dart',
    'lib/src/elements/json_view.html',
    'lib/src/elements/library_ref.dart',
    'lib/src/elements/library_ref.html',
    'lib/src/elements/library_view.dart',
    'lib/src/elements/library_view.html',
    'lib/src/elements/logging.dart',
    'lib/src/elements/logging.html',
    'lib/src/elements/megamorphiccache_view.dart',
    'lib/src/elements/megamorphiccache_view.html',
    'lib/src/elements/metrics.dart',
    'lib/src/elements/metrics.html',
    'lib/src/elements/nav_bar.dart',
    'lib/src/elements/nav_bar.html',
    'lib/src/elements/object_common.dart',
    'lib/src/elements/object_common.html',
    'lib/src/elements/object_view.dart',
    'lib/src/elements/object_view.html',
    'lib/src/elements/objectpool_view.dart',
    'lib/src/elements/objectpool_view.html',
    'lib/src/elements/observatory_application.dart',
    'lib/src/elements/observatory_application.html',
    'lib/src/elements/observatory_element.dart',
    'lib/src/elements/observatory_element.html',
    'lib/src/elements/persistent_handles.dart',
    'lib/src/elements/persistent_handles.html',
    'lib/src/elements/ports.dart',
    'lib/src/elements/ports.html',
    'lib/src/elements/script_inset.dart',
    'lib/src/elements/script_inset.html',
    'lib/src/elements/script_ref.dart',
    'lib/src/elements/script_ref.html',
    'lib/src/elements/script_view.dart',
    'lib/src/elements/script_view.html',
    'lib/src/elements/service_ref.dart',
    'lib/src/elements/service_ref.html',
    'lib/src/elements/service_view.dart',
    'lib/src/elements/service_view.html',
    'lib/src/elements/sliding_checkbox.dart',
    'lib/src/elements/sliding_checkbox.html',
    'lib/src/elements/timeline_page.dart',
    'lib/src/elements/timeline_page.html',
    'lib/src/elements/view_footer.dart',
    'lib/src/elements/view_footer.html',
    'lib/src/elements/vm_connect.dart',
    'lib/src/elements/vm_connect.html',
    'lib/src/elements/vm_ref.dart',
    'lib/src/elements/vm_ref.html',
    'lib/src/elements/vm_view.dart',
    'lib/src/elements/vm_view.html',
    'lib/src/elements/css/shared.css',
    'lib/src/elements/img/chromium_icon.png',
    'lib/src/elements/img/dart_icon.png',
    'lib/src/elements/img/isolate_icon.png',
    'lib/src/service/object.dart',
    'lib/tracer.dart',
    'lib/utils.dart',
    'web/index.html',
    'web/main.dart',
    'web/favicon.ico',
    'web/third_party/trace_viewer_full.html',
    'web/timeline.js',
    'web/timeline.html',
  ],
}
